# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  mkShell,
  writeScriptBin,
  nixpresso,
  golangci-lint,
}:
let
  generate-docs = writeScriptBin "update-docs" ''
    mkdir -p docs
    install -m 644 ${nixpresso.docs}/*.md docs/
  '';
in
mkShell {
  inputsFrom = [
    nixpresso
    nixpresso.assets
  ];

  packages = [
    generate-docs
    golangci-lint
  ];

  hardeningDisable = [ "all" ];
}
