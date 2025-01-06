// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix

import (
	"context"
	"io"
)

type prefetchResult struct {
	Hash      string
	StorePath string
}

func AddToStore(ctx context.Context, rd io.Reader, name string) (string, string, error) {
	var result prefetchResult

	if err := NixUnmarshal(ctx, 0, 0, &result, rd, nil, "store", "prefetch-file", "--hash-type", "sha256", "--name", name, "file:///dev/stdin"); err != nil {
		return "", "", err
	}

	return result.Hash, result.StorePath, nil
}
