// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"bytes"
	"fmt"
	"io"
	"reflect"
	"slices"
	"strconv"
	"strings"
)

type Encoder struct {
	wr     io.Writer
	Indent string
}

func NewEncoder(wr io.Writer, indent string) *Encoder {
	return &Encoder{wr: wr, Indent: indent}
}

func (e *Encoder) Encode(v any) error {
	return marshalValue(reflect.ValueOf(v), e.wr, e.Indent, 0)
}

type Marshaler interface {
	MarshalNix() (string, error)
}

func Marshal(v any, indent string) (string, error) {
	var buf bytes.Buffer

	if err := NewEncoder(&buf, indent).Encode(v); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func marshalValue(v reflect.Value, wr io.Writer, indent string, level int) (err error) {
	p := strings.Repeat(indent, level)

	writeString := func(s string) error {
		if _, err := wr.Write([]byte(s)); err != nil {
			return fmt.Errorf("failed to write: %w", err)
		}
		return nil
	}

	if v.Kind() == reflect.Pointer && v.IsNil() {
		return writeString("null")
	}

	switch w := v.Interface().(type) {
	case Marshaler:
		n, err := w.MarshalNix()
		if err != nil {
			return err
		}

		if err := writeString(n); err != nil {
			return err
		}

	case error:
		fmt.Fprintf(wr, `"%s"`, EscapeString(w.Error()))

	case fmt.Stringer:
		fmt.Fprintf(wr, `"%s"`, EscapeString(w.String()))

	case string:
		fmt.Fprintf(wr, `"%s"`, EscapeString(w))

	case int, int8, int16, int32, int64:
		fmt.Fprintf(wr, "%d", w)

	case uint, uint8, uint16, uint32, uint64:
		fmt.Fprintf(wr, "%d", w)

	case float32, float64:
		fmt.Fprintf(wr, "%f", w)

	case bool:
		fmt.Fprint(wr, strconv.FormatBool(w))

	default:
		switch v.Kind() {
		case reflect.Ptr:
			return marshalValue(v.Elem(), wr, indent, level)

		case reflect.Slice, reflect.Array:
			if indent == "" {
				err = writeString("[ ")
			} else {
				err = writeString("[\n")
			}
			if err != nil {
				return err
			}

			for i := 0; i < v.Len(); i++ {
				if indent != "" {
					if err = writeString(p + indent); err != nil {
						return err
					}
				}

				if err := marshalValue(v.Index(i), wr, indent, level+1); err != nil {
					return err
				}

				if indent == "" {
					err = writeString(" ")
				} else {
					err = writeString("\n")
				}
				if err != nil {
					return err
				}
			}
			if err = writeString(p + "]"); err != nil {
				return err
			}

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
				err = writeString(p + "{ ")
			} else {
				err = writeString("{\n")
			}
			if err != nil {
				return err
			}

			for _, kv := range kvs {
				if indent != "" {
					if err := writeString(p + indent); err != nil {
						return err
					}
				}

				if err := writeString(kv.Key); err != nil {
					return err
				}
				if err := writeString(" = "); err != nil {
					return err
				}

				if err := marshalValue(kv.Value, wr, indent, level+1); err != nil {
					return err
				}

				if indent == "" {
					err = writeString("; ")
				} else {
					err = writeString(";\n")
				}
				if err != nil {
					return err
				}
			}
			if err = writeString(p + "}"); err != nil {
				return err
			}

		default:
			return fmt.Errorf("unsupported type: %s", v.Type())
		}
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
