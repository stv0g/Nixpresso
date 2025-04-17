# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  runCommandNoCC,
  writeText,
  nixdoc,
}:
let
  inherit (lib) concatStringsSep mapAttrsToList;

  prefix = "nixpresso.lib";

  categories = {
    cookie = "HTTP Cookies";
    html = "HTML escaping";
    url = "URL parsing";

    customisation = "Customisation";
    handlers = "Trivial Handlers";
    response = "Handlers support";
    trivial = "Trivial helpers";
  };

  indexPage = writeText "index.md" ''
    # Nixpresso Library Reference

    This is the documentation for the Nixpresso library.

    It is availble as a passthru from the main Nixpresso derivation. E.g:

    ```nix
    let
      lib = import "''${builtins.fetchTarball "https://github.com/stv0g/Nixpresso/archive/refs/heads/main.tar.gz"}/lib" { };
    in
    lib.handlers.htmlError { status = 404; details = "Not found"; }
    ```

    Or as a Flake output:

    ```nix
    let
      inherit (builtins.getFlake "github:stv0g:nixpresso") lib;
    in
    lib.handlers.htmlError { status = 404; details = "Not found"; }
    ```

    ## Contents

    ${concatStringsSep "\n" (
      mapAttrsToList (name: value: "* ${value}: [`${prefix}.${name}`](./${name}.md)") categories
    )}
  '';
in
runCommandNoCC "nixpresso-docs" { nativeBuildInputs = [ nixdoc ]; } ''
  mkdir $out

  ${concatStringsSep "\n" (
    mapAttrsToList (
      name: value:
      ''nixdoc --file ${../lib + "/${name}.nix"} --category "${name}" --description "${value}" --prefix "${prefix}" > $out/${name}.md''
    ) categories
  )}

  cp ${indexPage} $out/index.md
''
