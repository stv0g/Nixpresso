// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package util

import (
	"reflect"
	"strings"
)

func FilterFieldsByTag[T any](a T, tag string, pred func(tag string) bool) (c T) {
	return FilterFields[T](a, func(v reflect.Value, sf reflect.StructField) bool {
		tagValue := sf.Tag.Get(tag)
		if tagValue == "" {
			return false
		}

		tagParts := strings.Split(tagValue, ",")
		return pred(tagParts[0])
	})
}

func FilterFields[T any](a T, pred func(v reflect.Value, sf reflect.StructField) bool) (c T) {
	v := reflect.ValueOf(a)
	t := v.Type()

	if v.Kind() != reflect.Struct {
		panic("ClearFields: argument must be a struct")
	}

	vc := reflect.ValueOf(&c).Elem()

	for i := 0; i < t.NumField(); i++ {
		f := v.Field(i)
		cf := vc.Field(i)
		sf := t.Field(i)

		if !pred(f, sf) {
			continue
		}

		cf.Set(f)
	}

	return c
}

func FilterMapByKey[V any, K comparable](m map[K]V, pred func(k K) bool) map[K]V {
	return FilterMap[K, V](m, func(k K, _ V) bool {
		return pred(k)
	})
}

func FilterMap[K comparable, V any](m map[K]V, pred func(k K, v V) bool) map[K]V {
	c := map[K]V{}

	for k, v := range m {
		if !pred(k, v) {
			continue
		}

		c[k] = v
	}

	return c
}
