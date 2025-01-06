# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  hello,
  nixpresso,
}:
let
  inherit (builtins) pathExists;
  inherit (nixpresso.lib) mkHandler;
in
mkHandler
  {
    description = "Gets build log of a derivation";
  }
  {
    body = hello;
    mode = "log";

    # Rebuild if it already exists in the store
    # in order to streaming build output in real-time.
    rebuild = pathExists hello.outPath;
  }
