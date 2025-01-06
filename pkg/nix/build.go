// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"context"
	"io"
	"strings"

	"github.com/stv0g/nixpresso/pkg/util"
)

func Build(ctx context.Context, drv string, output string, withPTY bool, verbose int, stderr io.Writer, argv ...string) (string, error) {
	argv2 := []string{"build", "--no-link", "--print-out-paths", drv + "^" + output}
	argv2 = append(argv2, argv...)

	pty := 0
	if withPTY {
		pty = util.StdinPTY | util.StderrPTY
	}

	stdout, _, err := Nix(ctx, pty, verbose, nil, nil, stderr, argv2...)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(stdout)), nil
}
