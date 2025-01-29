// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"os/exec"
	"strings"

	"al.essio.dev/pkg/shellescape"
	"github.com/stv0g/nixpresso/pkg/util"
)

var Executable = "nix"

func Nix(ctx context.Context, pty, verbose int, stdin io.Reader, stdout io.Writer, stderr io.Writer, argv ...string) ([]byte, []byte, error) {
	argv2 := []string{"--extra-experimental-features", "nix-command"}
	argv2 = append(argv2, argv...)

	cmd := exec.CommandContext(ctx, Executable, argv2...)

	slog.Debug("Invoking: " + shellescape.QuoteCommand(cmd.Args))

	return util.Run(cmd, pty, verbose, stdin, stdout, stderr)
}

func NixUnmarshal(ctx context.Context, pty, verbose int, result any, stdin io.Reader, stderr io.Writer, argv ...string) (err error) {
	argv2 := []string{}
	argv2 = append(argv2, argv...)
	argv2 = append(argv2, "--json")

	var stdout []byte
	if stdout, _, err = Nix(ctx, pty, verbose, stdin, nil, stderr, argv2...); err != nil {
		return err
	}

	if err := json.Unmarshal(stdout, result); err != nil {
		return fmt.Errorf("failed to unmarshal: %w", err)
	}

	return nil
}

func EscapeString(s string) string {
	r := strings.NewReplacer(`"`, `\"`, `\`, `\\`, `${`, `\${`)
	return r.Replace(s)
}

func EscapeIndentedString(s string) string {
	r := strings.NewReplacer(`''`, `'''`, `$`, `''$`)
	return r.Replace(s)
}

func FilterOptions(args []string) []string {
	opts := []string{}

	for i := 0; i < len(args); i++ {
		if args[i] == "--option" {
			if i+2 >= len(args) {
				continue
			}

			opts = append(opts, args[i], args[i+1], args[i+2])
			i += 2
		}
	}

	return opts
}

type Environment struct {
	CurrentSystem string
	StoreDir      string
	LangVersion   int
	NixVersion    string
}

func GetEnvironment(ctx context.Context) (e Environment, err error) {
	if err := NixUnmarshal(ctx, 0, 0, &e, nil, nil, "eval", "--impure", "--expr", "{ inherit (builtins)  storeDir currentSystem langVersion nixVersion; }"); err != nil {
		return e, err
	}

	return e, nil
}
