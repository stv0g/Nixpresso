# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ buildNpmPackage }:
buildNpmPackage {
  pname = "assets";
  version = "1.0";

  src = ./.;
  npmDepsHash = "sha256-o3mz84gDXZT98HWpDok89q8XyxaqEfajj8tv/yGuluY=";

  dontNpmInstall = true;

  postInstall = ''
    cp -r ./dist $out
  '';
}
