// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http/httptest"
	"os"
	"time"

	"github.com/sergi/go-diff/diffmatchpatch"
)

type TestCase struct {
	Name string `json:"name"`

	Arguments      Arguments   `json:"arguments"`
	ExpectedResult *EvalResult `json:"results"`

	Recorder     *httptest.ResponseRecorder `json:"-"`
	ActualResult *EvalResult                `json:"-"`
}

func (tc *TestCase) Run(h *Handler, overwriteResults bool) (err error) {
	tc.Recorder = httptest.NewRecorder()

	req := &Request{
		handler:  h,
		response: tc.Recorder,
		timings:  map[string]time.Duration{},
	}

	if req.request, err = tc.Arguments.Request(); err != nil {
		return fmt.Errorf("failed to assemble request: %w", err)
	}

	if err := req.Handle(); err != nil {
		return fmt.Errorf("failed to run test case: %w", err)
	}

	tc.ActualResult = &req.result

	er, err := json.MarshalIndent(tc.ExpectedResult, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal expected result: %w", err)
	}

	ar, err := json.MarshalIndent(tc.ActualResult, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal actual result: %w", err)
	}

	if !bytes.Equal(ar, er) {
		dmp := diffmatchpatch.New()
		diffs := dmp.DiffMain(string(er), string(ar), false)
		diffPretty := dmp.DiffPrettyText(diffs)

		return fmt.Errorf("expected result does not match actual result:\n%s", diffPretty)
	}

	return nil
}

func (h *Handler) Test(testSpecsFilename string, overwriteResults bool) error {
	var tests []*TestCase

	f, err := os.ReadFile(testSpecsFilename)
	if err != nil {
		return fmt.Errorf("failed to read test specs: %w", err)
	}

	if err := json.Unmarshal(f, &tests); err != nil {
		return fmt.Errorf("failed to parse test specs: %w", err)
	}

	for _, tc := range tests {
		start := time.Now()
		err := tc.Run(h, overwriteResults)
		elapsed := time.Since(start)

		if err != nil {
			slog.Error("Test case failed",
				slog.String("name", tc.Name),
				slog.Duration("duration", elapsed))
			os.Stderr.WriteString(err.Error())
		} else {
			slog.Info("Test case passed",
				slog.String("name", tc.Name),
				slog.Duration("duration", elapsed))
		}
	}

	if overwriteResults {
		for _, tc := range tests {
			tc.ExpectedResult = tc.ActualResult
		}

		f, err := json.MarshalIndent(tests, "", "  ")
		if err != nil {
			return fmt.Errorf("failed to marshal test results: %w", err)
		}

		if err := os.WriteFile(testSpecsFilename, f, 0o644); err != nil {
			return fmt.Errorf("failed to write test results: %w", err)
		}
	}

	return nil
}
