// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"context"

	"github.com/stv0g/nixpresso/pkg/util"
)

func Eval(ctx context.Context, withPTY bool, verbose int, result any, argv ...string) error {
	argv2 := []string{"eval", "--show-trace"}
	argv2 = append(argv2, argv...)

	pty := 0
	if withPTY {
		pty = util.StdinPTY | util.StderrPTY
	}

	if err := NixUnmarshal(ctx, pty, verbose, result, nil, nil, argv2...); err != nil {
		return err
	}

	return nil
}
