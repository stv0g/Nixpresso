# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  lib,
  nixpresso,
}:
let
  inherit (lib)
    concatStrings
    drop
    removePrefix
    splitString
    concatStringsSep
    elemAt
    ;
  inherit (nixpresso.lib) handlers html mkHandler;
in
mkHandler { description = "Evaluate Nixpkgs derivations and serve them as files."; } (
  { path, basePath, ... }:
  let
    nPath = removePrefix "/" path;
    pathComponents = splitString "/" nPath;

    attr = elemAt pathComponents 0;

    examples = [
      "hello/"
      "tango-icon-theme/share/icons/Tango/128x128/"
    ];
  in
  (
    if pkgs ? "${attr}" then # Package exists
      let
        pkg = pkgs.${attr};
        storePath = "${pkg}";
      in
      handlers.servePath { fsPath = storePath; } {
        basePath = basePath + "/" + attr;
        path = "/" + concatStringsSep "/" (drop 1 pathComponents);
      }
    else if attr == "" then
      handlers.html {
        title = "Nixpkgs";
        main = ''
          <h1>Serve content from realized Nixpkgs derivations</h1>

          <section>
            <h3>Examples</h3>
            <ul>
              ${concatStrings (
                map (x: ''<li><a href="${html.escape x}">${html.escape x}</a></li>'') examples
              )}
            </ul>
          </section>

          <section>
            <button onclick="history.back()">Back</button>
          <section>
        '';
      }
    else
      handlers.htmlError {
        status = nixpresso.lib.status.notFound;
        details = "package not found: ${attr}";
      }
  )
)
