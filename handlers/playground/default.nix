# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  nixpresso,
}:
let
  inherit (nixpresso.lib)
    handlers
    customisation
    mkHandler
    ;
in
mkHandler
  {
    description = "A Nix and Nixpresso playground";

    pty = true;
  }
  (
    let
      callHandler = customisation.callWith pkgs;
      examples = callHandler ./handlers/examples.nix { };
      ui = callHandler ./handlers/ui.nix { };
    in
    handlers.ifPathEquals "/examples.json" examples ui
  )
