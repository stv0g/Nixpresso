# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
}:
let
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;
in
mkHandler
  {
    description = "Serve a path from the local file system";
  }
  (
    handlers.servePath {
      fsPath = /. + builtins.getEnv "HOME";
    }
  )
