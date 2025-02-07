# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ buildNpmPackage }:
buildNpmPackage {
  pname = "assets";
  version = "1.0";

  src = ./.;
  npmDepsHash = "sha256-zu0hod7FNooWeGvXUCDmni6xo/U5oVaJ5wgRbYGUbhU=";

  postInstall = ''
    cp ./dist/* $out
    cp -r ./images $out
    cp *.txt $out

    rm -rf $out/lib
  '';
}
