# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixosTests,
  nixpresso,
}:
let
  inherit (builtins) pathExists;
  inherit (nixpresso.lib) mkHandler;

  test = nixosTests.alice-lg;
in
mkHandler
  {
    description = "Run a NixOS test in a VM and streams logs via HTTP chunked transfer encoding";
  }
  {
    mode = "log";
    rebuild = pathExists test.outPath; # Only rebuild if it already exists
    body = test;
    output = "out";
  }
