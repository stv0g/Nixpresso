# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  hello,
  nixpresso,
}:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler
  {
    description = "Show the derivation path of a Nixpkgs package in JSON format (append <tt>?recursive</tt> to include dependencies)";
  }
  (
    {
      query,
      ...
    }:
    {
      body = hello;
      mode = "derivation";

      recursive = query ? recursive;
    }
  )
