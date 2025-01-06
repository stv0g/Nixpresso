// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

type EvalResult struct {
	Status  int                 `json:"status,omitempty"`
	Headers map[string][]string `json:"headers,omitempty"`

	Mode      string            `json:"mode,omitempty"`
	Type      string            `json:"type,omitempty"`
	Body      string            `json:"body,omitempty"`
	SubPath   string            `json:"subPath,omitempty"`
	Args      []string          `json:"args,omitempty"`
	Env       map[string]string `json:"env,omitempty"`
	Output    string            `json:"output,omitempty"`
	Stream    bool              `json:"stream,omitempty"`
	Recursive bool              `json:"recursive,omitempty"`
	Rebuild   bool              `json:"rebuild,omitempty"`
	PTY       bool              `json:"pty,omitempty"`
}
