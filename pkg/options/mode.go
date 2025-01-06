// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package options

import (
	"fmt"
	"slices"
	"strings"
)

const (
	ServeMode      = "serve"
	RunMode        = "run"
	LogMode        = "log"
	DerivationMode = "derivation"
)

var (
	AllModes     = []string{ServeMode, LogMode, DerivationMode, RunMode}
	DefaultModes = []string{ServeMode, LogMode, DerivationMode}
	BuildModes   = []string{ServeMode, LogMode, RunMode}
)

type Modes []string

func (m *Modes) String() string {
	s := []string{}
	for _, m := range *m {
		s = append(s, string(m))
	}
	return strings.Join(s, ", ")
}

func (m *Modes) Set(s string) error {
	for _, p := range strings.Split(s, ",") {
		if !slices.Contains(AllModes, p) {
			return fmt.Errorf("invalid mode: %s", p)
		}

		*m = append(*m, p)
	}

	return nil
}

func (m *Modes) Type() string {
	return "mode"
}
