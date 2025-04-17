# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ hello, nixpresso }:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler { description = "Serve a path from a realized Nixpkgs derivation"; } {
  body = hello;
  subPath = "bin/hello";
}
