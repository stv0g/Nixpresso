# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

final: _: {
  nixpresso = final.callPackage ./derivation.nix { };
}
