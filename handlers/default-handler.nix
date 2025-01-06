# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  nixpresso,
}:
let
  inherit (lib)
    attrsToList
    filterAttrs
    ;
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;

  exampleHandlers = filterAttrs (name: _: name != "default") nixpresso.handlers;
  exampleRoutes = map ({ name, value }: handlers.ifPathHasPrefix "/${name}" value) (
    attrsToList exampleHandlers
  );
in
mkHandler
  {
    description = "Main entry point for all examples";
  }
  (
    handlers.router {
      routes = [
        (handlers.ifPathEquals "/" nixpresso.handlers.home)
        (handlers.ifPathEquals "/favicon.ico" {
          body = nixpresso.assets;
          subPath = "images/nixpresso-favicon.svg";
        })
      ] ++ exampleRoutes;
    }
  )
