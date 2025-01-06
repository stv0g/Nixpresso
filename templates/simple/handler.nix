# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  cowsay,
  nixpresso,
}:
nixpresso.lib.mkHandler
  {
    description = "My first Nixpresso handler";
  }
  (
    {
      query,
      ...
    }:
    let
      inherit (lib) concatStringsSep;

      users = query.user or [ "stv0g" ];
      message = "Hello, ${concatStringsSep ", " users}!";
    in
    {
      mode = "run";
      body = cowsay;
      subPath = "/bin/cowsay";
      args = [
        message
      ];
    }
  )
