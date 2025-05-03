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
  {
    path,
    basePath,
    meta,
    ...
  }:
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
        title = meta.description;
        main = ''
          <p>
            This handler serves build outputs from Nixpkgs derivations.
          </p>

          <section>
            <h2>Examples</h2>
            <ul>
              ${concatStrings (
                map (x: ''<li><a href="${html.escape x}">${html.escape x}</a></li>'') examples
              )}
            </ul>
          </section>

          <section>
           <fieldset role="group">
             <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
             <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/nixpkgs.nix';"><span class="mdi mdi-github"/> Code</button></a>
           </fieldset>
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
