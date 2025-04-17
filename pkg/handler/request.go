// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"bytes"
	"context"
	"errors"
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
	"github.com/stv0g/nixpresso/pkg/cache"
	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/options"
	"github.com/stv0g/nixpresso/pkg/util"
)

type Request struct {
	handler   *Handler
	request   *http.Request
	response  http.ResponseWriter
	arguments Arguments
	result    *EvalResult

	body           string
	headersWritten bool
	timings        map[string]time.Duration
}

func (r *Request) Handle() (err error) {
	if r.arguments, err = r.handler.ArgumentsFromRequest(r.request); err != nil {
		return fmt.Errorf("failed to assemble arguments: %w", err)
	}

	if err = r.handle(); err != nil {
		slog.Error("Failed to handle request", slog.Any("error", err))

		if _, ok := r.handler.InspectResult.ExpectedArgs["error"]; !ok {
			return err
		}

		// In case the handler can handle errors, we pass the error and the previous evaluation result
		// to the handler and evaluate again
		r.arguments.Result = r.result
		r.arguments.Error = NewError(err)
		r.result = nil

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

	if !slices.Contains(r.handler.opts.AllowedModes, r.result.Mode) {
		return ForbiddenModeError(r.result.Mode)
	}

	if !slices.Contains(r.handler.opts.AllowedTypes, r.result.Type) {
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

	argv := []string{r.handler.opts.Handler}
	argv = append(argv, "--apply", fmt.Sprintf("h: h %s", argsNix))
	argv = append(argv, r.handler.opts.NixArgs...)

	var cacheKey cache.NamedStringKey
	if r.canEvalCache() {
		var argvCache []string
		if len(r.handler.InspectResult.EvalCacheIgnore.Args) == 0 && len(r.handler.InspectResult.EvalCacheIgnore.Headers) == 0 {
			argvCache = argv
		} else if argvCache, err = r.evalArgs(true); err != nil {
			return fmt.Errorf("failed to assemble Nix arguments for cache: %w", err)
		}

		cacheKey = cache.NamedStringKey(strings.Join(argvCache, " "))
		if r.result, err = r.handler.cache.Get(cacheKey); err == nil {
			slog.Debug("Cache hit",
				slog.String("key", cacheKey.Name()))

			if nixHeader, ok := r.result.Headers["Nix"]; ok {
				nixHeader[0] += ", cached"
			} else {
				r.result.Headers["Nix"] = []string{"cached"}
			}
		} else {
			if errors.Is(err, cache.ErrMiss) {
				slog.Debug("Cache miss",
					slog.String("key", cacheKey.Name()))
			} else {
				return fmt.Errorf("failed to get from cache: %w", err)
			}
		}
	}

	if r.result == nil {
		r.result = &EvalResult{}

		durEval := r.measure("eval", func() {
			ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.opts.MaxEvalTime)
			err = nix.Eval(ctx, r.handler.InspectResult.PTY, r.handler.opts.Verbose, &r.result, argv...)
			cancel()
		})
		if err != nil {
			return err
		}

		if r.handler.opts.Verbose >= 5 {
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

		if cacheKey != "" {
			if err := r.handler.cache.Set(cacheKey, r.result, 60*time.Minute); err != nil {
				return fmt.Errorf("failed to set cache: %w", err)
			}
		}
	}

	return nil
}

func (r *Request) build() (err error) {
	slog.Debug("Starting build",
		slog.String("derivation", r.body))

	argv := []string{}
	argv = append(argv, nix.FilterOptions(r.handler.opts.NixArgs)...)

	if r.result.Rebuild || (r.result.Mode == options.LogMode && r.result.Stream) {
		argv = append(argv, "--rebuild")
	}

	var stderr io.Writer
	if r.result.Stream && r.result.Mode == options.LogMode {
		argv = append(argv, "--print-build-logs")
		stderr = r.response
	}

	durBuild := r.measure("build", func() {
		ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.opts.MaxBuildTime)
		r.body, err = nix.Build(ctx, r.body, r.result.Output, r.result.PTY, r.handler.opts.Verbose, stderr, argv...)
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
		stdout = r.response
		stderr = r.response
	} else {
		stdout = combined
		stderr = combined
	}

	r.writeHeader(r.result.Status)

	argv := []string{}
	argv = append(argv, r.handler.opts.RunArgs...)
	argv = append(argv, r.result.Args...)

	if r.arguments.Body != nil {
		body, err := os.Open(*r.arguments.Body)
		if err != nil {
			return fmt.Errorf("failed to open request body '%s': %w", *r.arguments.Body, err)
		}
		defer body.Close() //nolint:errcheck

		stdin = body
	} else {
		stdin = r.request.Body
	}

	slog.Debug("Starting run: " + shellescape.QuoteCommand(append([]string{r.body}, argv...)))

	var cmd *exec.Cmd
	durRun := r.measure("run", func() {
		ctx, cancel := context.WithTimeout(r.request.Context(), r.handler.opts.MaxRunTime)
		cmd = exec.CommandContext(ctx, r.body, argv...)
		for key, value := range r.result.Env {
			cmd.Env = append(cmd.Env, key+"="+value)
		}

		_, _, err = util.Run(cmd, pty, r.handler.opts.Verbose, stdin, stdout, stderr)
		cancel()
	})
	if err != nil {
		return err
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
		if len(r.result.Body) > int(r.handler.opts.MaxResponseBytes) {
			return fmt.Errorf("response body exceeds maximum size: %d > %d Bytes", len(r.result.Body), r.handler.opts.MaxResponseBytes)
		}

		rd = strings.NewReader(r.result.Body)

	case options.PathType, options.DerivationType:
		r.body = filepath.Join(r.body, r.result.SubPath)

		if r.body, err = filepath.EvalSymlinks(r.body); err != nil {
			return fmt.Errorf("failed to evaluate symlink '%s': %w", r.body, err)
		}

		if !r.handler.checkPath(r.body) {
			return ForbiddenPathError(r.body)
		}

		if fi, err := os.Stat(r.body); err != nil {
			return fmt.Errorf("failed to stat response body path '%s': %w", r.body, err)
		} else if int(fi.Size()) > int(r.handler.opts.MaxResponseBytes) {
			return fmt.Errorf("response body exceeds maximum size: %d > %d Bytes", len(r.result.Body), r.handler.opts.MaxResponseBytes)
		} else if isStorePath := strings.HasPrefix(r.body, r.handler.env.StoreDir); !isStorePath {
			modTime = fi.ModTime()
		}

		if f, err := os.Open(r.body); err != nil {
			return fmt.Errorf("failed to open result: %w", err)
		} else {
			rd = f
			defer f.Close() //nolint:errcheck
		}
	default:
		return fmt.Errorf("invalid combination of type and mode")
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

	if _, _, err := nix.Nix(r.request.Context(), pty, r.handler.opts.Verbose, nil, r.response, nil, "log", r.body); err != nil {
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

	if _, _, err := nix.Nix(r.request.Context(), pty, r.handler.opts.Verbose, nil, r.response, nil, args...); err != nil {
		return fmt.Errorf("failed to get derivation: %w", err)
	}

	return nil
}

func (r *Request) writeHeader(status int) {
	if r.headersWritten {
		slog.Warn("Headers already written. Consider disabling streaming responses.")
		return
	}

	hdr := r.response.Header()
	hdr.Set("Server", fmt.Sprintf("Nixpresso/%s (Nix %s, %d)", pkg.Version, r.handler.env.NixVersion, r.handler.env.LangVersion))

	if len(r.timings) > 0 {
		timingsFormatted := []string{}
		for name, dur := range r.timings {
			timingsFormatted = append(timingsFormatted, fmt.Sprintf("%s;dur=%d", name, dur.Milliseconds()))
		}

		hdr.Set("Server-Timing", strings.Join(timingsFormatted, ", "))
	}

	if status != 0 {
		r.response.WriteHeader(status)
		r.headersWritten = true
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

func (r *Request) evalArgs(forCache bool) ([]string, error) {
	args := r.arguments

	if forCache {
		args = util.FilterFieldsByTag(r.arguments, "json", func(field string) bool {
			return !slices.Contains(r.handler.InspectResult.EvalCacheIgnore.Args, field)
		})

		if args.Header != nil {
			headers := map[string][]string(*args.Header)

			filteredHeaders := util.FilterMapByKey(headers, func(k string) bool {
				return !slices.Contains(r.handler.InspectResult.EvalCacheIgnore.Headers, k)
			})

			args.Header = (*http.Header)(&filteredHeaders)
		}
	}

	argsNix, err := nix.Marshal(args, "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to assemble Nix arguments: %w", err)
	}

	argv := []string{r.handler.opts.Handler}
	argv = append(argv, "--apply", fmt.Sprintf("h: h %s", argsNix))
	argv = append(argv, r.handler.opts.NixArgs...)

	return argv, nil
}

func (r *Request) canEvalCache() bool {
	if r.handler.cache == nil {
		return false
	}

	if ccHdr := r.request.Header.Get("Cache-Control"); ccHdr != "" {
		for _, ccDirective := range strings.Split(ccHdr, ",") {
			ccDirective = strings.TrimSpace(ccDirective)

			if ccDirective == "no-cache" {
				return false
			}
		}
	}

	return true
}
