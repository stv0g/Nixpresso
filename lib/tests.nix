# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib, url }:
let
  cases = lib.runTests {
    testUnescapeURL = {
      expr = url.unescape "hello";
      expected = "hello";
    };
  };
in
if cases == [ ] then
  "Unit tests successful"
else
  throw "Path unit tests failed: ${lib.generators.toPretty { } cases}"
