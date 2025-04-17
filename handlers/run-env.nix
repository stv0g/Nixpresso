# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ coreutils, nixpresso }:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler { description = "Pass environment variables to a command"; } {
  body = coreutils;
  subPath = "bin/env";
  mode = "run";
  env = {
    MYVAR = "myvalue";
  };
}
