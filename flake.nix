# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  description = "A HTTP server delegating request handling to a Nix function";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    (
      {
        overlays = {
          default = self.overlays.nixpresso;
          nixpresso = import ./overlay.nix;
        };

        templates = {
          default = self.templates.simple;
          simple = {
            description = "A self-contained example to get you started with writing your own Nixpresso handlers";
            path = ./templates/simple;
          };
        };

        nixosModules = {
          default = self.nixosModules.nixpresso;
          nixpresso = import ./module.nix { inherit self; };
        };

        lib = import ./lib { lib = nixpkgs.lib; };
      }
      // flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.nixpresso ];
          };
        in
        {
          devShells = {
            default = self.devShells.${system}.nixpresso;
            nixpresso = pkgs.callPackage ./shell.nix { };
          };

          packages = {
            default = pkgs.nixpresso;
            nixpresso = pkgs.nixpresso;

            nixpresso-docker = pkgs.callPackage ./docker.nix { inherit self; };
          };

          inherit (pkgs.nixpresso) handlers;

          checks = {
            default = self.checks.${system}.nixpresso;
            nixpresso = pkgs.callPackage ./check.nix { inherit self; };
          };
        }
      )
    );
}
