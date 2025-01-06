# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  description = "A self-contained example to get you started with writing your own Nixpresso handlers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpresso.url = "github:stv0g/nixpresso";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpresso,
      flake-utils,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixpresso.overlays.nixpresso ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nixpresso ];
        };

        packages = {
          default = pkgs.writeShellApplication {
            name = "nixpresso-simple";
            runtimeInputs = [ pkgs.nixpresso ];
            text = "nixpresso --allow-mode run ${self}";
          };
        };

        handlers = {
          default = pkgs.callPackage ./handler.nix { };
        };
      }
    ));
}
