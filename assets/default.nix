# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ buildNpmPackage }:
buildNpmPackage {
  pname = "assets";
  version = "1.0";

  src = ./.;
  npmDepsHash = "sha256-2KGZFMdXR7+MJ6Q3ODlO62ebi+yYbZQKsQFibjsGKuc=";

  dontNpmInstall = true;

  postInstall = ''
    cp -r ./dist $out
  '';
}
