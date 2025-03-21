# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  callPackage,
  buildGoModule,
  nix,
}:
buildGoModule rec {
  name = "nixpresso";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-47hCxtCzFBiiXfei4t7pKOLxWK+2a6PT1L3mPUK6NZ4=";

  ldflags = [
    "-X 'github.com/stv0g/nixpresso/pkg.Version=${version}'"
    "-X 'github.com/stv0g/nixpresso/pkg/nix.Executable=${nix}/bin/nix'"
  ];

  passthru = {
    assets = callPackage ./assets { };
    lib = callPackage ./lib { };
    handlers = callPackage ./handlers { };
    docs = callPackage ./docs { };
  };

  nativeCheckInputs = [
    nix
  ];

  checkFlags = [
    "-skip TestAddToStore"
  ];

  meta = {
    homepage = "https://nixpresso.dev";
    description = "Modern encryption tool with small explicit keys";
    license = lib.licenses.asl20;
    mainProgram = "nixpresso";
    maintainers = with lib.maintainers; [ stv0g ];
  };
}
