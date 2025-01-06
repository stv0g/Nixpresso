// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"al.essio.dev/pkg/shellescape"
	"github.com/stv0g/nixpresso/pkg"
	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/options"
	"github.com/stv0g/nixpresso/pkg/util"
)

type Request struct {
	handler   *Handler
	request   *http.Request
	response  http.ResponseWriter
	arguments Arguments
	result    EvalResult

	body           string
	headersWritten bool
	timings        map[string]time.Duration
}

func (r *Request) Handle() (err error) {
	if r.arguments, err = r.handler.ArgumentsFromRequest(r.request); err != nil {
		return fmt.Errorf("failed to assemble arguments: %w", err)
	}

	if err = r.handle(); err != nil {
		if _, ok := r.handler.ExpectedArgs["error"]; !ok {
			return err
		}

		// In case the handler can handle errors, we pass the error and the previous evaluation result
		// to the handler and evaluate again
		r.arguments.Result = &r.result
		r.arguments.Error = NewError(err)

		if err = r.handle(); err != nil {
			return err
		}
	}

	return nil
}

func (r *Request) handle() error {
	if err := r.eval(); err != nil {
		return fmt.Errorf("failed to evaluate: %w", err)
	}

	if !slices.Contains(r.handler.AllowedModes, r.result.Mode) {
		return ForbiddenModeError(r.result.Mode)
	}

	if !slices.Contains(r.handler.AllowedTypes, r.result.Type) {
		return ForbiddenTypeError(r.result.Type)
	}

	hdr := r.response.Header()
	for name, values := range r.result.Headers {
		hdr[name] = values
	}

	r.body = r.result.Body
	if r.body == "" {
		r.writeHeader(r.result.Status)
		return nil
	}

	if r.result.Stream {
		if fw, ok := r.response.(*util.FlushingResponseWriter); ok {
			slog.Debug("Enabling response flushing", slog.String("mode", "line"))
			fw.Mode = util.FlushModeLine
		}
	}

	if doBuild := r.result.Type == options.DerivationType && slices.Contains(options.BuildModes, r.result.Mode); doBuild {
		if err := r.build(); err != nil {
			return fmt.Errorf("failed to build: %w", err)
		}
	}

	switch r.result.Mode {
	case options.RunMode:
		if err := r.run(); err != nil {
			return fmt.Errorf("failed to run: %w", err)
		}

	case options.ServeMode:
		if err := r.serve(); err != nil {
			return fmt.Errorf("failed to serve: %w", err)
		}

	case options.LogMode:
		if err := r.log(); err != nil {
			return fmt.Errorf("failed to get logs: %w", err)
		}

	case options.DerivationMode:
		if err := r.derivation(); err != nil {
			return fmt.Errorf("failed to get derivation: %w", err)
		}
	}

	return nil
}

func (r *Request) eval() error {
	slog.Debug("Starting evaluation")

	argsNix, err := nix.Marshal(r.arguments, "  ")
	if err != nil {
		return fmt.Errorf("failed to assemble Nix arguments: %w", err)
	}

	durEval := r.measure("eval", func() {
		ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.MaxEvalTime)
		err = r.evalCall(ctx, &r.result, "--apply", fmt.Sprintf("h: h %s", argsNix))
		cancel()
	})
	if err != nil {
		return err
	}

	if r.handler.Verbose >= 5 {
		slog.Info("Finished evaluation",
			slog.Duration("after", durEval))
		util.DumpJSON(r.result)
	} else {
		slog.Info("Finished evaluation",
			slog.Duration("after", durEval),
			slog.String("body", r.result.Body),
			slog.String("mode", string(r.result.Mode)),
			slog.String("type", string(r.result.Type)))
	}

	return nil
}

func (r *Request) build() (err error) {
	slog.Debug("Starting build",
		slog.String("derivation", r.body))

	argv := []string{}
	argv = append(argv, nix.FilterOptions(r.handler.NixArgs)...)

	if r.result.Rebuild || (r.result.Mode == options.LogMode && r.result.Stream) {
		argv = append(argv, "--rebuild")
	}

	var stderr io.Writer
	if r.result.Stream && r.result.Mode == options.LogMode {
		argv = append(argv, "--print-build-logs")
		stderr = r.response
	}

	durBuild := r.measure("build", func() {
		ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.MaxBuildTime)
		r.body, err = nix.Build(ctx, r.body, r.result.Output, r.result.PTY, r.handler.Verbose, stderr, argv...)
		cancel()
	})
	if err != nil {
		return err
	}

	slog.Info("Finished build",
		slog.Any("result", r.body),
		slog.Duration("after", durBuild))

	return nil
}

func (r *Request) run() (err error) {
	if r.result.Type != options.DerivationType && r.result.Type != options.PathType {
		return fmt.Errorf("invalid combination of type and mode")
	}

	if !r.handler.checkPath(r.body) {
		return ForbiddenPathError(r.body)
	}

	var (
		stdin          io.Reader
		stdout, stderr io.Writer
		combined       = &bytes.Buffer{}
		pty            int
	)

	r.body = filepath.Join(r.body, r.result.SubPath)

	if r.result.PTY {
		pty = util.StdinPTY | util.StdoutPTY | util.StderrPTY
	}

	if r.result.Stream {
		r.writeHeader(r.result.Status)

		stdout = r.response
		stderr = r.response
	} else {
		stdout = combined
		stderr = combined
	}

	argv := []string{}
	argv = append(argv, r.handler.RunArgs...)
	argv = append(argv, r.result.Args...)

	if r.arguments.Body != nil {
		body, err := os.Open(*r.arguments.Body)
		if err != nil {
			return fmt.Errorf("failed to open request body '%s': %w", *r.arguments.Body, err)
		}
		defer body.Close()

		stdin = body
	} else {
		stdin = r.request.Body
	}

	slog.Debug("Starting run: " + shellescape.QuoteCommand(argv))

	var cmd *exec.Cmd
	durRun := r.measure("run", func() {
		ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.MaxRunTime)
		cmd = exec.CommandContext(ctx, r.body, argv...)
		for key, value := range r.result.Env {
			cmd.Env = append(cmd.Env, key+"="+value)
		}

		_, _, err = util.Run(cmd, pty, r.handler.Verbose, stdin, stdout, stderr)
		cancel()
	})
	if err != nil {
		return fmt.Errorf("failed to run: %w", err)
	}

	if !r.result.Stream {
		hdr := r.response.Header()
		hdr.Set("Content-Type", "text/plain")
		hdr.Set("Content-Length", fmt.Sprint(combined.Len()))

		r.writeHeader(r.result.Status)

		if _, err := r.response.Write(combined.Bytes()); err != nil {
			return fmt.Errorf("failed to write response: %w", err)
		}
	}

	slog.Info("Finished run",
		slog.Int("rc", cmd.ProcessState.ExitCode()),
		slog.Duration("after", durRun))

	return nil
}

func (r *Request) serve() (err error) {
	var modTime time.Time
	var rd io.ReadSeeker

	switch r.result.Type {
	case options.StringType:
		if len(r.result.Body) > int(r.handler.MaxResponseBytes) {
			return fmt.Errorf("response body exceeds maximum size: %d > %d Bytes", len(r.result.Body), r.handler.MaxResponseBytes)
		}

		rd = strings.NewReader(r.result.Body)

	case options.PathType, options.DerivationType:
		r.body = filepath.Join(r.body, r.result.SubPath)

		if r.body, err = filepath.EvalSymlinks(r.body); err != nil {
			return fmt.Errorf("failed to evaluate symlink '%s': %w.", r.body, err)
		}

		if !r.handler.checkPath(r.body) {
			return ForbiddenPathError(r.body)
		}

		if fi, err := os.Stat(r.body); err != nil {
			return fmt.Errorf("failed to stat response body path '%s': %w", r.body, err)
		} else if int(fi.Size()) > int(r.handler.MaxResponseBytes) {
			return fmt.Errorf("response body exceeds maximum size: %d > %d Bytes", len(r.result.Body), r.handler.MaxResponseBytes)
		} else if isStorePath := strings.HasPrefix(r.body, r.handler.StoreDir); !isStorePath {
			modTime = fi.ModTime()
		}

		if f, err := os.Open(r.body); err != nil {
			return fmt.Errorf("failed to open result: %w", err)
		} else {
			rd = f
			defer f.Close()
		}
	default:
		return fmt.Errorf("invalid combination of type and mode.")
	}

	r.writeHeader(0) // WriteHeader() is called by ServeContent()
	http.ServeContent(r.response, r.request, r.body, modTime, rd)

	return nil
}

func (r *Request) log() error {
	if r.result.Type != "derivation" {
		return fmt.Errorf("invalid combination of type and mode")
	}

	if r.result.Stream {
		return nil // Logs already emitted during build
	}

	hdr := r.response.Header()
	hdr.Set("Content-Type", "text/plain")

	pty := 0
	if r.result.PTY {
		pty = util.StdinPTY | util.StderrPTY
	}

	if _, _, err := nix.Nix(r.request.Context(), pty, r.handler.Verbose, nil, r.response, nil, "log", r.body); err != nil {
		return fmt.Errorf("failed to get log: %w", err)
	}

	return nil
}

func (r *Request) derivation() error {
	if r.result.Type != options.DerivationType {
		return fmt.Errorf("invalid combination of type and mode")
	}

	hdr := r.response.Header()
	hdr.Set("Content-Type", "application/json")

	args := []string{"derivation", "show", r.result.Body}
	if r.result.Recursive {
		args = append(args, "--recursive")
	}

	pty := 0
	if r.result.PTY {
		pty = util.StdinPTY | util.StderrPTY
	}

	if _, _, err := nix.Nix(r.request.Context(), pty, r.handler.Verbose, nil, r.response, nil, args...); err != nil {
		return fmt.Errorf("failed to get derivation: %w", err)
	}

	return nil
}

func (r *Request) writeHeader(status int) {
	if r.headersWritten {
		slog.Warn("Headers already written. Consider disabling streaming responses.")
		return
	}

	timingsFormatted := []string{}
	for name, dur := range r.timings {
		timingsFormatted = append(timingsFormatted, fmt.Sprintf("%s;dur=%d", name, dur.Milliseconds()))
	}

	hdr := r.response.Header()
	hdr.Set("Server-Timing", strings.Join(timingsFormatted, ", "))
	hdr.Set("Server", fmt.Sprintf("Nixpresso/%s (Nix %s, %d)", pkg.Version, r.handler.NixVersion, r.handler.LangVersion))

	if status != 0 {
		r.response.WriteHeader(status)
		r.headersWritten = true
	}
}

func (r *Request) evalCall(ctx context.Context, result any, argv ...string) error {
	argv2 := []string{r.handler.Handler}
	argv2 = append(argv2, argv...)
	argv2 = append(argv2, r.handler.NixArgs...)

	if r.handler.Pure && r.handler.EvalCache {
		return nix.EvalCached(ctx, r.handler.InspectResult.PTY, r.handler.Verbose, result, argv2...)
	} else {
		return nix.Eval(ctx, r.handler.InspectResult.PTY, r.handler.Verbose, result, argv2...)
	}
}

func (r *Request) writeError(err error) {
	if r.headersWritten {
		slog.Warn("Headers already written. Consider disabling streaming responses.")
		return
	}

	hdr := r.response.Header()
	hdr.Del("Content-Length")
	hdr.Set("Content-Type", "text/plain; charset=utf-8")
	hdr.Set("X-Content-Type-Options", "nosniff")

	http.Error(r.response, err.Error(), http.StatusInternalServerError)
}

func (r *Request) measure(id string, cb func()) time.Duration {
	start := time.Now()
	cb()
	dur := time.Since(start)

	r.timings[id] = dur

	return dur
}
