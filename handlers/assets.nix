# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
}:
let
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;
in
mkHandler
  {
    description = "Serve static assets such as CSS, JavaScript, and images for the examples";
  }
  (
    handlers.servePath {
      fsPath = nixpresso.assets;
    }
  )
