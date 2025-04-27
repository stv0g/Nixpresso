# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  lib,
  runCommandNoCC,
  texliveSmall,
}:
let
  inherit (nixpresso.lib) mkHandler;

  texlive = texliveSmall.withPackages (
    ps: with ps; [
      standalone
      pgf-blur
    ]
  );
in
mkHandler
  {
    description = "Show the derivation path of a Nixpkgs package in JSON format (append <tt>?recursive</tt> to include dependencies)";
  }
  (
    { ... }@request:
    let
      documentTemplated =
        runCommandNoCC "document.pdf"
          {
            prettyRequest = lib.generators.toPretty { } request;
          }
          ''
            substituteAll ${./document.tex} $out
          '';
    in
    {
      body =
        runCommandNoCC "document.pdf"
          {
            buildInputs = [ texlive ];
          }
          ''
            xelatex ${documentTemplated}
            mv *-document.pdf $out
          '';

      headers = {
        "Content-Type" = "application/pdf";
      };
    }
  )
