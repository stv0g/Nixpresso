// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package util

import (
	"reflect"
	"slices"
	"testing"
)

type TestStruct struct {
	String  string  `json:"str"`
	Integer int     `json:"int"`
	Bool    bool    `json:"bool"`
	Pointer *string `json:"ptr"`
}

func TestFilterFields(t *testing.T) {
	someString := "test"

	input := TestStruct{String: "test", Integer: 42, Bool: true, Pointer: &someString}

	tests := []struct {
		name   string
		fields []string
		want   TestStruct
	}{
		{
			name:   "Filter single field",
			fields: []string{"str"},
			want:   TestStruct{String: "", Integer: 42, Bool: true, Pointer: &someString},
		},
		{
			name:   "Filter multiple fields",
			fields: []string{"str", "int"},
			want:   TestStruct{String: "", Integer: 0, Bool: true, Pointer: &someString},
		},
		{
			name:   "Filter all fields",
			fields: []string{"str", "int", "bool"},
			want:   TestStruct{String: "", Integer: 0, Bool: false, Pointer: &someString},
		},
		{
			name:   "Filter pointer field",
			fields: []string{"ptr"},
			want:   TestStruct{String: "test", Integer: 42, Bool: true, Pointer: nil},
		},
		{
			name:   "Filter non-existent field",
			fields: []string{"non_existent"},
			want:   TestStruct{String: "test", Integer: 42, Bool: true, Pointer: &someString},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			output := FilterFieldsByTag(input, "json", func(tag string) bool {
				return !slices.Contains(tt.fields, tag)
			})
			if !reflect.DeepEqual(output, tt.want) {
				t.Errorf("FilterFields() = %v, want %v", output, tt.want)
			}
		})
	}
}

func TestFilterKeys(t *testing.T) {
	input := map[string]int{"a": 1, "b": 2, "c": 3}

	tests := []struct {
		name string
		keys []string
		want map[string]int
	}{
		{
			name: "Clear single key",

			keys: []string{"a"},
			want: map[string]int{"b": 2, "c": 3},
		},
		{
			name: "Clear multiple keys",
			keys: []string{"a", "b"},
			want: map[string]int{"c": 3},
		},
		{
			name: "Clear all keys",
			keys: []string{"a", "b", "c"},
			want: map[string]int{},
		},
		{
			name: "Clear non-existent key",
			keys: []string{"d"},
			want: map[string]int{"a": 1, "b": 2, "c": 3},
		},
		{
			name: "Clear some existent and some non-existent keys",
			keys: []string{"a", "d"},
			want: map[string]int{"b": 2, "c": 3},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			output := FilterMapByKey(input, func(k string) bool {
				return !slices.Contains(tt.keys, k)
			})
			if !reflect.DeepEqual(output, tt.want) {
				t.Errorf("ClearKeys() = %v, want %v", output, tt.want)
			}
		})
	}
}
