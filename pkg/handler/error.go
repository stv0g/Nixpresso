// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"errors"
	"fmt"
	"net/http"
	"os/exec"
	"syscall"
	"time"

	"github.com/stv0g/nixpresso/pkg/util"
)

type Error struct {
	Error error `json:"error,omitempty"`

	Status int `json:"status,omitempty"`

	Path       string        `json:"path,omitempty"`
	Args       []string      `json:"args,omitempty"`
	Env        []string      `json:"env,omitempty"`
	Dir        string        `json:"dir,omitempty"`
	Exited     bool          `json:"exited,omitempty"`
	PID        int           `json:"pid,omitempty"`
	Time       time.Duration `json:"time,omitempty"`
	ExitStatus int           `json:"exitStatus,omitempty"`
	TermSignal int           `json:"termSignal,omitempty"`
	StopSignal int           `json:"stopSignal,omitempty"`
	CoreDump   bool          `json:"coreDump,omitempty"`

	Stdout string `json:"stdout,omitempty"`
	Stderr string `json:"stderr,omitempty"`
}

func NewError(err error) (e *Error) {
	e = &Error{
		Error: err,
	}

	var re *util.RunError
	if ok := errors.As(err, &re); ok {
		e.Status = http.StatusInternalServerError

		e.Path = re.Cmd.Path
		e.Args = re.Cmd.Args
		e.Env = re.Cmd.Env
		e.Dir = re.Cmd.Dir
		e.Stdout = string(re.Stdout)
		e.Stderr = string(re.Stderr)

		var ee *exec.ExitError
		if ok := errors.As(re, &ee); ok {
			e.Exited = ee.Exited()
			e.PID = ee.Pid()
			e.Time = ee.SystemTime() + ee.UserTime()

			if ss, ok := ee.Sys().(syscall.WaitStatus); ok {
				switch {
				case ss.Exited():
					e.ExitStatus = ss.ExitStatus()
				case ss.Signaled():
					e.TermSignal = int(ss.Signal())
				case ss.Stopped():
					e.StopSignal = int(ss.StopSignal())
				}

				e.CoreDump = ss.CoreDump()
			}
		}
	}

	return e
}

func Errorf(status int, format string, args ...any) *Error {
	return &Error{
		Status: status,
		Error:  fmt.Errorf(format, args...),
	}
}

func ForbiddenModeError(mode string) error {
	return fmt.Errorf("mode '%s' is not allowed. Please start Nixpresso with '--allow-mode %s'", mode, mode)
}

func ForbiddenTypeError(typ string) error {
	return fmt.Errorf("type '%s' is not allowed. Please start Nixpresso with '--allow-type %s'", typ, typ)
}

func ForbiddenPathError(path string) error {
	return fmt.Errorf("path '%s' is not prefixed matched by allowed paths setting. Please start Nixpresso with '--allow-path %s'", path, path)
}
