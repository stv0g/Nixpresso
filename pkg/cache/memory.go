// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package cache

import (
	"fmt"
	"time"

	"github.com/elastic/go-freelru"
)

type MemoryCache[K Key, V any] struct {
	lru  *freelru.SyncedLRU[K, V]
	stop chan struct{}

	BeforeEviction func(key K, value V)
}

func NewMemoryCache[K Key, V any](capacity uint32) (c *MemoryCache[K, V], err error) {
	c = &MemoryCache[K, V]{
		stop: make(chan struct{}),
	}

	if c.lru, err = freelru.NewSynced[K, V](capacity, func(k K) uint32 {
		return k.Hash()
	}); err != nil {
		return nil, fmt.Errorf("failed to create LRU cache: %w", err)
	}

	go c.evict()

	return c, nil
}

func (c *MemoryCache[K, V]) Close() error {
	close(c.stop)

	return nil
}

func (c *MemoryCache[K, V]) SetOnEvict(f func(key K, value V)) {
	c.lru.SetOnEvict(f)
}

func (c *MemoryCache[K, V]) Get(key K) (value V, err error) {
	value, ok := c.lru.Get(key)
	if !ok {
		return value, ErrMiss
	}

	return value, nil
}

func (c *MemoryCache[K, V]) Set(key K, value V, ttl time.Duration) error {
	c.lru.AddWithLifetime(key, value, ttl)

	return nil
}

func (c *MemoryCache[K, V]) evict() {
	t := time.NewTicker(time.Minute)

	for {
		select {
		case <-t.C:
			c.lru.PurgeExpired()

		case <-c.stop:
			return
		}
	}
}
