// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package options

import (
	"fmt"
	"os"
	"strings"
)

type Paths []string

func (t *Paths) String() string {
	s := []string{}
	for _, t := range *t {
		s = append(s, string(t))
	}
	return strings.Join(s, ", ")
}

func (t *Paths) Set(p string) error {
	for _, p := range strings.Split(p, ",") {
		if fi, err := os.Stat(p); err != nil {
			return fmt.Errorf("invalid path: %s", p)
		} else if !fi.IsDir() {
			return fmt.Errorf("path is not a directory: %s", p)
		}

		*t = append(*t, p)
	}

	return nil
}

func (t *Paths) Type() string {
	return "path"
}
