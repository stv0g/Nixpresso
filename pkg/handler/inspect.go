// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/util"

	_ "embed"
)

//go:embed inspect.nix
var inspectExpression string

type EvalCacheIgnore struct {
	Args    []string `json:"args,omitempty"`
	Headers []string `json:"headers,omitempty"`
	Query   []string `json:"query,omitempty"`
}

type InspectResult struct {
	Description string `json:"description,omitempty"`
	Path        string `json:"path,omitempty"`

	EvalCacheIgnore EvalCacheIgnore `json:"evalCacheIgnore,omitempty"`

	ExpectedArgs map[string]bool `json:"expectedArgs,omitempty"`
	Pure         bool            `json:"pure,omitempty"`

	EvalArgs []string `json:"evalArgs,omitempty"`
	PTY      bool     `json:"pty,omitempty"`
}

func (h *Handler) inspect() (err error) {
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if h.FlakeReference != "" {
		if err := h.inspectFlake(ctx); err != nil {
			return err
		}
	}

	if err := h.inspectHandler(ctx); err != nil {
		return err
	}

	slog.Info("Successfully inspected handler")

	if h.opts.Verbose >= 3 {
		util.DumpJSON(h.InspectResult)
	}

	return nil
}

func (h *Handler) inspectFlake(ctx context.Context) error {
	// Copy Flake to store if its not already there
	if !strings.HasPrefix(strings.TrimPrefix(h.FlakeReference, "path:"), h.env.StoreDir) {
		expr := fmt.Sprintf(`builtins.getFlake "%s"`, h.FlakeReference)
		argv := []string{"--impure", "--option", "extra-experimental-features", "flakes", "--expr", expr}
		argv = append(argv, h.opts.NixArgs...)

		if err := nix.Eval(ctx, false, h.opts.Verbose, &h.FlakeStorePath, argv...); err != nil {
			return err
		}
	}

	if h.FlakeStorePath != "" {
		h.opts.Handler = "path:" + h.FlakeStorePath + "#" + h.FlakeAttribute
	}

	return nil
}

func (h *Handler) inspectHandler(ctx context.Context) error {
	args := []string{}
	args = append(args, h.opts.NixArgs...)
	args = append(args, "--apply", inspectExpression, h.opts.Handler)

	if err := nix.Eval(ctx, false, h.opts.Verbose, &h.InspectResult, args...); err != nil {
		return err
	}

	return nil
}
