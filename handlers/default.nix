# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs ? import <nixpkgs> {
    overlays = [ (import ../overlay.nix) ];
  },
}:
let
  inherit (builtins) readDir;
  inherit (pkgs.lib)
    filterAttrs
    mapAttrs'
    removeSuffix
    ;
  inherit (pkgs.nixpresso.lib)
    customisation
    trivial
    ;

  callHandler = customisation.callWith pkgs;

  contents = filterAttrs (
    name: _: name != "default.nix" && name != "default-handler.nix"
  ) (readDir ./.);

  handlers = mapAttrs' (
    name: type:
    let
      handler = callHandler (./. + "/${name}") { };
      path = if type == "directory" then "${name}/default.nix" else name;

      extraMeta = {
        inherit path;
      };
    in
    {
      name = removeSuffix ".nix" name;
      value = (trivial.toFunctor handler) // {
        meta = handler.meta or { } // extraMeta;
      };
    }
  ) contents;
in
handlers
// {
  default = callHandler ./default-handler.nix { };
}
