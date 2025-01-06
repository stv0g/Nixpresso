# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ buildNpmPackage }:
buildNpmPackage {
  pname = "assets";
  version = "1.0";

  src = ./.;
  npmDepsHash = "sha256-6ludyZDAatNz9pRh4VwTXXsS8gswTikoYsmJy6xh5ns=";

  postInstall = ''
    cp ./dist/* $out
    cp -r ./images $out

    rm -rf $out/lib
  '';
}
