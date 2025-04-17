# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ nixpresso }:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler { description = "Serve a static text response"; } { body = "Hello, world!"; }
