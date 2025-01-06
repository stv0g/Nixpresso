// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package options

import (
	"time"
)

type Options struct {
	Handler  string // "Installable" which is passed to "nix eval" && "nix run"
	BasePath string

	EvalCache    bool
	AllowStore   bool
	AllowedPaths Paths
	AllowedModes Modes
	AllowedTypes Types

	NixArgs []string
	RunArgs []string

	MaxRequestTime time.Duration
	MaxEvalTime    time.Duration
	MaxBuildTime   time.Duration
	MaxRunTime     time.Duration

	MaxRequestBytes  int64
	MaxResponseBytes int64

	Verbose int
}
