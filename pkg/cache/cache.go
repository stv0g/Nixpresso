// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package cache

import (
	"errors"
	"time"
)

var (
	ErrMiss    = errors.New("key not found")
	ErrExpired = errors.New("key expired")
)

type Cache[K comparable, V any] interface {
	Get(key K) (value V, err error)
	Set(key K, value V, ttl time.Duration) error
}

type CacheEntry[K comparable, V any] struct {
	Value   V
	Expires time.Time
}
