# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  # We use our own version of callPackageWith which does not use makeOverridable.
  customisation = import ./customisation.nix { inherit lib; };

  call = customisation.callWith (
    {
      inherit
        lib
        lib'
        call
        ;

    }
    // lib'
  );

  lib' = {
    cookie = call ./cookie.nix { };
    customisation = call ./customisation.nix { };
    handlers = call ./handlers.nix { };
    html = call ./html.nix { };
    response = call ./response.nix { };
    status = call ./status.nix { };
    trivial = call ./trivial.nix { };
    url = call ./url.nix { };

    inherit (lib'.response) mkHandler;
  };
in
lib'
