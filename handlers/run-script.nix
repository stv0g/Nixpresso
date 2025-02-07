# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  writeShellApplication,
  lib,
  nixpresso,
}:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler
  {
    description = "Run a shell script with streaming output";
  }
  (
    { query, ... }:
    let
      inherit (lib) head;

      count = head (query.count or [ "100" ]);
    in
    {
      body = writeShellApplication {
        name = "script";
        text = ''
          for i in $(seq ${count}); do
            echo "Step $i (some very long line for enforce buffer flushing)"
            sleep 0.1
          done
        '';
      };

      mode = "run";
      stream = false;
      subPath = "bin/script";
    }
  )
