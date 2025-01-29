// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package options

import (
	"time"
)

type Options struct {
	Handler  string `json:"handler"` // "Installable" which is passed to "nix eval" && "nix run"
	BasePath string `json:"basePath"`

	EvalCache    bool  `json:"evalCache"`
	AllowStore   bool  `json:"allowStore"`
	AllowedPaths Paths `json:"allowedPaths"`
	AllowedModes Modes `json:"allowedModes"`
	AllowedTypes Types `json:"allowedTypes"`

	NixArgs []string `json:"nixArgs"`
	RunArgs []string `json:"runArgs"`

	MaxRequestTime time.Duration `json:"maxRequestTime"`
	MaxEvalTime    time.Duration `json:"maxEvalTime"`
	MaxBuildTime   time.Duration `json:"maxBuildTime"`
	MaxRunTime     time.Duration `json:"maxRunTime"`

	MaxRequestBytes  int64 `json:"maxRequestBytes"`
	MaxResponseBytes int64 `json:"maxResponseBytes"`

	Verbose int `json:"verbose"`
}
