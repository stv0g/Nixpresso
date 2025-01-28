// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package util

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"

	"al.essio.dev/pkg/shellescape"
	"github.com/creack/pty"
	"golang.org/x/sys/unix"
)

type RunError struct {
	error

	*exec.Cmd
	Stderr []byte
	Stdout []byte
}

func (e *RunError) Unwrap() error {
	return e.error
}

func (e *RunError) Error() string {
	return fmt.Sprintf("failed to run: %s", shellescape.QuoteCommand(e.Cmd.Args))
}

const (
	StdinPTY int = (1 << iota)
	StdoutPTY
	StderrPTY
)

func Run(cmd *exec.Cmd, withPTY int, verbose int, stdin io.Reader, stdout, stderr io.Writer) (stdoutBytes, stderrBytes []byte, error error) {
	stdoutBuf := &bytes.Buffer{}
	stderrBuf := &bytes.Buffer{}

	if stdout == nil {
		stdout = stdoutBuf
	} else {
		stdout = io.MultiWriter(stdoutBuf, stdout)
	}

	if stderr == nil {
		stderr = stderrBuf
	} else {
		stderr = io.MultiWriter(stderrBuf, stderr)
	}

	if verbose >= 10 {
		stdout = io.MultiWriter(stdout, os.Stderr)
		stderr = io.MultiWriter(stderr, os.Stderr)
	}

	if withPTY&StdinPTY == 0 {
		cmd.Stdin = stdin
	}
	if withPTY&StdoutPTY == 0 {
		cmd.Stdout = stdout
	}
	if withPTY&StderrPTY == 0 {
		cmd.Stderr = stderr
	}

	if withPTY != 0 {
		f, err := pty.StartWithSize(cmd, &pty.Winsize{
			Rows: 40,
			Cols: 160,
		})
		if err != nil {
			return nil, nil, fmt.Errorf("failed to start PTY: %w", err)
		}
		defer f.Close()

		go func() {
			var dst io.Writer
			if withPTY&StdoutPTY != 0 {
				dst = stdout
			} else {
				dst = stderr
			}

			if _, err := io.Copy(dst, f); err != nil && !errors.Is(err, unix.EIO) {
				slog.Error("Failed to copy PTY to stdout", slog.Any("error", err))
			}
		}()

		if stdin != nil {
			go func() {
				if _, err := io.Copy(f, stdin); err != nil && !errors.Is(err, unix.EIO) {
					slog.Error("Failed to copy from stdin to PTY", slog.Any("error", err))
				}
			}()
		}
	} else {
		if err := cmd.Start(); err != nil {
			return nil, nil, fmt.Errorf("failed to start: %w", err)
		}
	}

	if err := cmd.Wait(); err != nil {
		return stdoutBuf.Bytes(), stderrBuf.Bytes(),
			&RunError{
				error:  err,
				Cmd:    cmd,
				Stdout: stdoutBuf.Bytes(),
				Stderr: stderrBuf.Bytes(),
			}
	}

	return stdoutBuf.Bytes(), stderrBuf.Bytes(), nil
}
