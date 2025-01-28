// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"context"
	"encoding/json"
	"fmt"
	"hash/maphash"
	"log/slog"

	"github.com/stv0g/nixpresso/pkg/util"
	sync_map "github.com/zolstein/sync-map"
)

func Eval(ctx context.Context, withPTY bool, verbose int, result any, argv ...string) error {
	argv2 := []string{"eval", "--show-trace"}
	argv2 = append(argv2, argv...)

	pty := 0
	if withPTY {
		pty = util.StdinPTY | util.StderrPTY
	}

	if err := NixUnmarshal(ctx, pty, verbose, result, nil, nil, argv2...); err != nil {
		return err
	}

	return nil
}

var (
	evalCache     sync_map.Map[uint64, []byte]
	evalCacheSeed = maphash.MakeSeed()
)

func cacheKey(argv ...string) uint64 {
	h := maphash.Hash{}
	h.SetSeed(evalCacheSeed)

	for _, arg := range argv {
		if _, err := h.WriteString(arg); err != nil {
			panic(err)
		}
	}

	return h.Sum64()
}

func EvalCached(ctx context.Context, withPTY bool, verbose int, result any, argv ...string) (err error) {
	key := cacheKey(argv...)

	resultBuf, ok := evalCache.Load(key)
	if !ok {
		slog.Debug("Cache miss for evaluation", slog.Uint64("key", key))

		argv2 := []string{"eval", "--json", "--show-trace"}
		argv2 = append(argv2, argv...)

		pty := 0
		if withPTY {
			pty = util.StdinPTY | util.StderrPTY
		}

		resultBuf, _, err = Nix(ctx, pty, verbose, nil, nil, nil, argv2...)
		if err != nil {
			return err
		}

		evalCache.Store(key, resultBuf)
	} else {
		slog.Info("Cache hit for evaluation", slog.Uint64("key", key))
	}

	if err := json.Unmarshal(resultBuf, result); err != nil {
		return fmt.Errorf("failed to unmarshal: %w", err)
	}

	return nil
}
