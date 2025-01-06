# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  nixpresso,
}:
let
  inherit (builtins) getFlake;
  inherit (lib)
    attrByPath
    concatStrings
    concatStringsSep
    drop
    elemAt
    isDerivation
    length
    pathExists
    removePrefix
    replaceStrings
    splitString
    ;
  inherit (nixpresso.lib)
    handlers
    html
    mkHandler
    ;
in
mkHandler
  {
    description = "Serve a path from a flake package";

  }
  (
    {
      path,
      ...
    }:
    let
      nPath = removePrefix "/" path;
      pathComponents = splitString "@" nPath;
      flakeRef = elemAt pathComponents 0;
      rest = elemAt pathComponents 1;

      restParts = splitString "/" rest;
      attr = elemAt restParts 0;
      subPath = if length restParts > 1 then "/" + concatStringsSep "/" (drop 1 restParts) else "";

      attrs = splitString "." attr;

      flake = getFlake flakeRef;

      body = attrByPath attrs "" flake;

      examples = [
        "nixpkgs#legacyPackages.x86_64-linux.hello.meta"
        "nixpkgs#legacyPackages.x86_64-linux.hello.version"
        "nixpkgs#legacyPackages.x86_64-linux.hello/bin/hello"
        "nixpkgs#legacyPackages.x86_64-linux.hello/share/"
      ];
    in
    if nPath == "" then
      handlers.html {
        title = "Flake";
        main = ''
          <h1>Serve content from Flake outputs</h1>

          <section>
            <h3>Examples</h3>
            <ul>
              ${concatStrings (
                map (x: "<li><a href=\"./${replaceStrings [ "#" ] [ "@" ] x}\">${x}</a></li>") (
                  map html.escape examples
                )
              )}
            </ul>
          </section>

          <section>
            <button onclick="history.back()">Back</button>
          <section>
        '';
      }
    else if isDerivation body && pathExists "${body}${subPath}" then
      handlers.servePath
        {
          fsPath = body;
        }
        {
          path = subPath;
          basePath = path;
        }
    else
      {
        inherit
          subPath
          body
          ;
      }
  )
