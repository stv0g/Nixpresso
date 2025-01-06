// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"bytes"
	"fmt"
	"reflect"
	"slices"
	"strings"
)

type Marshaler interface {
	MarshalNix() (string, error)
}

func Marshal(v any, indent string) (string, error) {
	var buf bytes.Buffer

	if err := marshalValue(reflect.ValueOf(v), &buf, indent, 0); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func marshalValue(v reflect.Value, buf *bytes.Buffer, indent string, level int) error {
	p := strings.Repeat(indent, level)

	if v.Kind() == reflect.Pointer && v.IsNil() {
		buf.WriteString("null")
		return nil
	}

	switch w := v.Interface().(type) {
	case Marshaler:
		n, err := w.MarshalNix()
		if err != nil {
			return err
		}

		buf.WriteString(n)
		return nil
	case error:
		v = reflect.ValueOf(w.Error())
	case fmt.Stringer:
		v = reflect.ValueOf(w.String())
	default:
	}

	switch v.Kind() {
	case reflect.Ptr:
		if v.IsNil() {
			buf.WriteString("null")
			return nil
		}

		return marshalValue(v.Elem(), buf, indent, level)
	case reflect.String:
		fmt.Fprintf(buf, `"%s"`, EscapeString(v.String()))

	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		fmt.Fprintf(buf, "%d", v.Int())

	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		fmt.Fprintf(buf, "%d", v.Uint())

	case reflect.Float32, reflect.Float64:
		fmt.Fprintf(buf, "%f", v.Float())

	case reflect.Bool:
		if v.Bool() {
			buf.WriteString("true")
		} else {
			buf.WriteString("false")
		}

	case reflect.Slice, reflect.Array:
		if indent == "" {
			buf.WriteString("[ ")
		} else {
			buf.WriteString("[\n")
		}

		for i := 0; i < v.Len(); i++ {
			if indent != "" {
				buf.WriteString(p + indent)
			}

			if err := marshalValue(v.Index(i), buf, indent, level+1); err != nil {
				return err
			}

			if indent == "" {
				buf.WriteString(" ")
			} else {
				buf.WriteString("\n")
			}
		}
		buf.WriteString(p + "]")

	case reflect.Map, reflect.Struct:
		kvs, err := keyValues(v, "nix", "json")
		if err != nil {
			return err
		}

		// Sort attributes alphabetically
		slices.SortFunc(kvs, func(a, b keyValue) int {
			return strings.Compare(a.Key, b.Key)
		})

		if indent == "" {
			buf.WriteString(p + "{ ")
		} else {
			buf.WriteString("{\n")
		}

		for _, kv := range kvs {
			if indent != "" {
				buf.WriteString(p + indent)
			}

			buf.WriteString(kv.Key)
			buf.WriteString(" = ")

			if err := marshalValue(kv.Value, buf, indent, level+1); err != nil {
				return err
			}

			if indent == "" {
				buf.WriteString("; ")
			} else {
				buf.WriteString(";\n")
			}
		}
		buf.WriteString(p + "}")

	default:
		return fmt.Errorf("unsupported type: %s", v.Type())
	}

	return nil
}

type keyValue struct {
	reflect.Value
	Key string
}

func keyValues(v reflect.Value, tags ...string) (kvs []keyValue, err error) {
	switch v.Kind() {
	case reflect.Map:
		return mapKeyValues(v)
	case reflect.Struct:
		return structKeyValues(v, tags...)
	default:
		return nil, fmt.Errorf("unsupported type: %s", v.Type())
	}
}

func mapKeyValues(v reflect.Value) (kvs []keyValue, err error) {
	if v.Type().Key().Kind() != reflect.String {
		return nil, fmt.Errorf("unsupported map key type: %s", v.Type().Key())
	}

	for _, key := range v.MapKeys() {
		kvs = append(kvs, keyValue{
			Value: v.MapIndex(key),
			Key:   key.String(),
		})
	}

	return kvs, nil
}

func structKeyValues(v reflect.Value, tags ...string) (kvs []keyValue, err error) {
	for i := 0; i < v.NumField(); i++ {
		var (
			field     = v.Type().Field(i)
			fieldName string
			omitEmpty bool
		)

		if !field.IsExported() {
			continue
		}

		for _, tag := range tags {
			if tagValue, ok := field.Tag.Lookup(tag); ok {
				tagParts := strings.Split(tagValue, ",")
				fieldName = tagParts[0]
				omitEmpty = slices.Contains(tagParts[1:], "omitempty")
				break
			}
		}

		if omitEmpty && v.Field(i).IsZero() {
			continue
		}

		if fieldName == "-" {
			continue
		} else if fieldName == "" {
			fieldName = field.Name
		}

		kvs = append(kvs, keyValue{
			Value: v.Field(i),
			Key:   fieldName,
		})
	}

	return kvs, nil
}
