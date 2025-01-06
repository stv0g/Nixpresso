# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs ? import <nixpkgs> { },
}:
pkgs.callPackage ./derivation.nix { }
