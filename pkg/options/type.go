// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package options

import (
	"fmt"
	"slices"
	"strings"
)

const (
	StringType     = "string"
	PathType       = "path"
	DerivationType = "derivation"
)

var AllTypes = []string{StringType, PathType, DerivationType}

type Types []string

func (t *Types) String() string {
	s := []string{}
	for _, t := range *t {
		s = append(s, t)
	}
	return strings.Join(s, ", ")
}

func (t *Types) Set(s string) error {
	for _, p := range strings.Split(s, ",") {
		if !slices.Contains(AllTypes, p) {
			return fmt.Errorf("invalid type: %s", p)
		}

		*t = append(*t, p)
	}

	return nil
}

func (t *Types) Type() string {
	return "type"
}
