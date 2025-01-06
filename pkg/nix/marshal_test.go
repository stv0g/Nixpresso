// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix_test

import (
	"fmt"
	"testing"

	"github.com/stv0g/nixpresso/pkg/nix"
)

type Person struct {
	Name string
	Age  int
}

func (p Person) String() string {
	return fmt.Sprintf("%v (%v years)", p.Name, p.Age)
}

func TestMarshal(t *testing.T) {
	tests := []struct {
		Name     string
		Input    any
		Indent   string
		Expected string
	}{
		{
			Name:     "string",
			Input:    `hello`,
			Expected: `"hello"`,
		},
		{
			Name:     "string single-quote",
			Input:    `hel'lo`,
			Expected: `"hel'lo"`,
		},
		{
			Name:     "string double-quote",
			Input:    `hel"lo`,
			Expected: `"hel\"lo"`,
		},
		{
			Name:     "string back-slash",
			Input:    `hel\lo`,
			Expected: `"hel\\lo"`,
		},
		{
			Name:     "string dollar",
			Input:    `hel${lo`,
			Expected: `"hel\${lo"`,
		},
		{
			Name:     "integer",
			Input:    123,
			Expected: "123",
		},
		{
			Name:     "float",
			Input:    123.456,
			Expected: "123.456000",
		},
		{
			Name:     "bool true",
			Input:    true,
			Expected: "true",
		},
		{
			Name:     "bool false",
			Input:    false,
			Expected: "false",
		},
		{
			Name:     "slice",
			Input:    []int{1, 2, 3},
			Expected: "[ 1 2 3 ]",
		},
		{
			Name:     "slice with indent",
			Input:    []int{1, 2, 3},
			Indent:   "  ",
			Expected: "[\n  1\n  2\n  3\n]",
		},
		{
			Name:     "array",
			Input:    [3]int{1, 2, 3},
			Expected: "[ 1 2 3 ]",
		},
		{
			Name:     "array with indent",
			Input:    []int{1, 2, 3},
			Indent:   "  ",
			Expected: "[\n  1\n  2\n  3\n]",
		},
		{
			Name:     "map",
			Input:    map[string]int{"one": 1, "two": 2},
			Expected: "{ one = 1; two = 2; }",
		},
		{
			Name:     "map with indent",
			Input:    map[string]int{"one": 1, "two": 2},
			Indent:   "  ",
			Expected: "{\n  one = 1;\n  two = 2;\n}",
		},
		{
			Name: "struct",
			Input: struct {
				Name  string
				Value int
			}{
				Name:  "test",
				Value: 42,
			},
			Expected: "{ Name = \"test\"; Value = 42; }",
		},
		{
			Name: "struct with tag",
			Input: struct {
				Name  string `nix:"name"`
				Value int    `json:"value"`
			}{
				Name:  "test",
				Value: 42,
			},
			Expected: "{ name = \"test\"; value = 42; }",
		},
		{
			Name: "struct with indent",
			Input: struct {
				Name  string
				Value int
			}{
				Name:  "test",
				Value: 42,
			},
			Indent:   "  ",
			Expected: "{\n  Name = \"test\";\n  Value = 42;\n}",
		},
		{
			Name: "struct nested",
			Input: struct {
				Name  string
				Value struct {
					Number int
					Slice  []int
				}
			}{
				Name: "test",
				Value: struct {
					Number int
					Slice  []int
				}{
					Number: 42,
					Slice:  []int{1, 2, 3},
				},
			},
			Expected: "{ Name = \"test\"; Value = { Number = 42; Slice = [ 1 2 3 ]; }; }",
		},
		{
			Name: "struct nested with indent",
			Input: struct {
				Name  string
				Value struct {
					Number int
					Slice  []int
				}
			}{
				Name: "test",
				Value: struct {
					Number int
					Slice  []int
				}{
					Number: 42,
					Slice:  []int{1, 2, 3},
				},
			},
			Indent:   "  ",
			Expected: "{\n  Name = \"test\";\n  Value = {\n    Number = 42;\n    Slice = [\n      1\n      2\n      3\n    ];\n  };\n}",
		},
		{
			Name:     "error",
			Input:    fmt.Errorf("test error"),
			Expected: `"test error"`,
		},
		{
			Name: "stringer",
			Input: Person{
				Name: "Alice",
				Age:  42,
			},
			Expected: `"Alice (42 years)"`,
		},
	}

	for _, test := range tests {
		t.Run(test.Name, func(t *testing.T) {
			result, err := nix.Marshal(test.Input, test.Indent)
			if err != nil {
				t.Errorf("unexpected error: %v", err)
			}

			if result != test.Expected {
				t.Errorf("expected %s, got %s", test.Expected, result)
			}
		})
	}
}
