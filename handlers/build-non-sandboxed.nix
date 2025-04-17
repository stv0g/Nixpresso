# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  writeShellApplication,
  runCommand,
  lib,
  nixpresso,
  curl,
  whois,
}:
let
  inherit (builtins) getEnv;
  inherit (nixpresso.lib) handlers mkHandler;
in
mkHandler { description = "Serve a response with a non-sandboxed build script"; } (
  let
    myScript = writeShellApplication {
      name = "script";

      runtimeInputs = [
        curl
        whois
      ];

      text = ''
        echo "Hello from a non-sandboxed build script!"
        echo
        echo "Time:               $(date)"
        echo "Random:               $RANDOM"

        echo
        echo "Env: MYENV=${getEnv "MYENV"}";

        IP=$(curl icanhazip.com)

        echo
        echo "Whois for $IP"
        echo
        whois -h bgp.tools "$IP"
      '';
    };
  in
  if false then
    handlers.htmlError {
      status = nixpresso.lib.status.forbidden;
      details = ''
        <p>Sandboxing is enabled. Please start Nixpresso either via</p>
        <ul>
          <li><code>nixpresso […] -- --option sandbox relaxed</code> or</li>
          <li><code>nixpresso […] -- --option sandbox false</code></li>
        </ul>
        <p>in order to to disable it.</p>'';
    }
  else
    {
      body =
        runCommand "test"
          {
            __noChroot = true; # Disable sandboxing
          }
          ''
            ${lib.getExe myScript} >> $out
          '';
    }
)
