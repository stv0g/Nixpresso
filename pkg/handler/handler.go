// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/stv0g/nixpresso/pkg/cache"
	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/options"
	"github.com/stv0g/nixpresso/pkg/util"
)

type Handler struct {
	opts          options.Options
	env           nix.Environment
	InspectResult InspectResult

	Expression string
	File       string

	FlakeAttribute string
	FlakeReference string
	FlakeStorePath string

	cache *cache.MemoryCache[cache.NamedStringKey, *EvalResult]
}

func NewHandler(opts options.Options) (h *Handler, err error) {
	h = &Handler{
		opts: opts,
	}

	if h.env, err = nix.GetEnvironment(context.Background()); err != nil {
		return nil, fmt.Errorf("failed to get Nix environment: %w", err)
	}

	// Get handler from command line
	if idx := slices.Index(h.opts.NixArgs, "--expr"); idx >= 0 {
		if len(h.opts.NixArgs) <= idx+1 {
			return nil, fmt.Errorf("missing argument to --expr")
		}
		h.Expression = h.opts.NixArgs[idx+1]
	} else if idx := slices.Index(h.opts.NixArgs, "--file"); idx >= 0 {
		if len(h.opts.NixArgs) <= idx+1 {
			return nil, fmt.Errorf("missing argument to --file")
		}
		h.File = h.opts.NixArgs[idx+1]
	} else {
		if parts := strings.SplitN(h.opts.Handler, "#", 2); len(parts) > 1 {
			h.FlakeReference = parts[0]
			h.FlakeAttribute = parts[1]
		} else {
			h.FlakeReference = parts[0]
		}

		// Set default Flake attribute
		if h.FlakeAttribute == "" {
			h.FlakeAttribute = fmt.Sprintf("handlers.%s.default", h.env.CurrentSystem)
		}

		// Make Flake reference path absolute
		if h.FlakeReference == "" {
			h.FlakeReference = "."
		}

		h.FlakeReference = strings.TrimPrefix(h.FlakeReference, "path:")

		if strings.HasPrefix(h.FlakeReference, ".") {
			if h.FlakeReference, err = filepath.Abs(h.FlakeReference); err != nil {
				return nil, fmt.Errorf("failed to get absolute path: %w", err)
			}
		}
	}

	if err := h.inspect(); err != nil {
		var runErr *util.RunError
		if errors.As(err, &runErr) {
			return nil, fmt.Errorf("failed to inspect handler: %s\nstdout:\n%s\nstderr:\n%s",
				runErr.Error(),
				string(runErr.Stdout),
				string(runErr.Stderr))
		} else {
			return nil, fmt.Errorf("failed to inspect handler: %w", err)
		}
	}

	if h.InspectResult.Pure && h.opts.EvalCache {
		if h.cache, err = cache.NewMemoryCache[cache.NamedStringKey, *EvalResult](16 << 10); err != nil {
			return nil, fmt.Errorf("failed to create cache: %w", err)
		}
	}

	return h, nil
}

func (h *Handler) ListenAndServe(addr string, rdTo, wrTo time.Duration, tlsCertFilename, tlsKeyFilename string) (err error) {
	s := &http.Server{
		Addr:                         addr,
		Handler:                      h,
		ReadTimeout:                  rdTo,
		WriteTimeout:                 wrTo,
		DisableGeneralOptionsHandler: true,
	}

	slog.Info("Start listening", slog.String("address", addr))

	if tlsCertFilename != "" && tlsKeyFilename != "" {
		err = s.ListenAndServeTLS(tlsCertFilename, tlsKeyFilename)
	} else {
		err = s.ListenAndServe()
	}
	if err != nil {
		return fmt.Errorf("failed to start server: %w", err)
	}

	return nil
}

func (h *Handler) ServeHTTP(wr http.ResponseWriter, req *http.Request) {
	r := &Request{
		request:  req,
		handler:  h,
		response: wr,

		timings: map[string]time.Duration{},
	}

	if h.opts.MaxRequestTime > 0 {
		ctx := req.Context()
		ctx, cancel := context.WithTimeout(ctx, h.opts.MaxRequestTime)
		defer cancel()

		r.request = req.WithContext(ctx)
	}

	if r.handler.opts.MaxRequestBytes > 0 {
		r.request.Body = http.MaxBytesReader(r.response, r.request.Body, r.handler.opts.MaxRequestBytes)
	}

	if f, ok := r.response.(http.Flusher); ok {
		r.response = &util.FlushingResponseWriter{
			ResponseWriter: r.response,
			Flusher:        f,
			Mode:           util.FlushModeNone,
		}
	}

	if err := r.Handle(); err != nil {
		r.writeError(err)
	}
}

func (h *Handler) checkPath(path string) bool {
	if util.ContainsDotDot(path) {
		return false
	}

	if h.opts.AllowStore && strings.HasPrefix(path, h.env.StoreDir) {
		return true
	}

	for _, allowedPath := range h.opts.AllowedPaths {
		if strings.HasPrefix(path, allowedPath) {
			return true
		}
	}

	return false
}
