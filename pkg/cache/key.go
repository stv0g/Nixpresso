// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package cache

import (
	"crypto/sha256"
	"encoding/hex"
	"hash/fnv"
)

type Key interface {
	comparable
	Hash() uint32
}

type NamedKey interface {
	Key
	Name() string
}

type NamedStringKey string

func (n NamedStringKey) Hash() uint32 {
	h := fnv.New32()
	h.Write([]byte(n))
	return h.Sum32()
}

func (n NamedStringKey) Name() string {
	dgst := sha256.Sum256([]byte(n))
	return hex.EncodeToString(dgst[:])
}
