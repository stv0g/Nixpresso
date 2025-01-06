// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package util

import (
	"encoding/json"
	"io"
	"os"
	"slices"
)

func SplitSlice[T comparable](s []T, sep T) (before, after []T) {
	i := slices.Index(s, sep)
	if i < 0 {
		return s, nil
	}

	return s[:i], s[i+1:]
}

func DumpJSON(v any) {
	DumpJSONf(os.Stderr, v)
}

func DumpJSONf(f io.Writer, v any) {
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	enc.Encode(v) //nolint: errcheck
}

func Zero[T any](p *T) (v T) {
	if p != nil {
		return *p
	}

	return v
}
