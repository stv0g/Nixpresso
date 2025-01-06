// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package nix_test

import (
	"bytes"
	"context"
	"fmt"
	"testing"

	"github.com/stv0g/nixpresso/pkg/nix"
)

func TestAddToStore(t *testing.T) {
	data := "hello"

	hash, path, err := nix.AddToStore(context.Background(), bytes.NewBufferString(data), "test")
	if err != nil {
		t.Fatal(err)
	}

	if hash != "sha256-LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=" {
		t.Errorf("Expected hash, got %s", hash)
	}

	if path != "/nix/store/b5xvjs4v94h13qh8xsnkigklhm90mh3m-test" {
		t.Errorf("Expected path, got %s", path)
	}

	expr := fmt.Sprintf(`
let
  inherit (builtins)
    fetchurl
    readFile
    ;

  file = fetchurl {
    name="test";
    url="file:///dev/stdin";
    sha256="%s";
  };
in
readFile file
`, hash)

	var content string
	if err := nix.Eval(context.Background(), false, 0, &content, "--expr", expr); err != nil {
		t.Fatal(err)
	}

	if content != data {
		t.Fatal("mismatch")
	}
}
