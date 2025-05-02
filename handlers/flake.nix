# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib, nixpresso }:
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
    mapAttrsToList
    splitString
    ;
  inherit (nixpresso.lib) handlers html mkHandler;
in
mkHandler { description = "Serve a path from a flake package"; } (
  { path, ... }:
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

    examples = {
      "nixpkgs#legacyPackages.x86_64-linux.hello.meta" =
        "serve the meta information of the hello package";
      "nixpkgs#legacyPackages.x86_64-linux.hello.version" = "serve the version of the hello package";
      "nixpkgs#legacyPackages.x86_64-linux.hello/bin/hello" = "serve the hello binary";
      "nixpkgs#legacyPackages.x86_64-linux.hello/share/" =
        "serve the share directory of the hello package";
    };
  in
  if nPath == "" then
    handlers.html {
      title = "Flake";
      main = ''
        <h1>Serve content from Flake outputs</h1>

        <p>
          This handler serves content from Flake outputs. It can be used to serve files from Nixpkgs or any other flake.
          <br />
          The path is specified as <code>flakeRef#attr1.attr2.attr3</code>. The first part is the flake reference, the second part is the attribute path.
        </p>

        <section>
          <h3>Examples</h3>
          <ul>
            ${concatStrings (
              mapAttrsToList (
                x: d: "<li><a href=\"./${replaceStrings [ "#" ] [ "@" ] (html.escape x)}\">${x}</a> ${d}</li>"
              ) examples
            )}
          </ul>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/flake.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';
    }
  else if isDerivation body && pathExists "${body}${subPath}" then
    handlers.servePath { fsPath = body; } {
      path = subPath;
      basePath = path;
    }
  else
    { inherit subPath body; }
)
