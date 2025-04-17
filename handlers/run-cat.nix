# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ nixpresso, coreutils }:
let
  inherit (nixpresso.lib) handlers mkHandler;
in
mkHandler
  { description = "Run a <tt>cat</tt> command to demonstrate request & response streaming"; }
  (
    { method, ... }:
    if method != "POST" then
      handlers.htmlError {
        status = nixpresso.lib.status.methodNotAllowed;
        details = ''
          <p>Please send some data via POST:</p>
          <p><code>echo "Hello world" | curl -v -X POST --data-binary @- http://localhost:8080/run-cat</code></p>'';
      }
    else
      {
        body = coreutils;
        subPath = "bin/cat";
        mode = "run";
      }
  )
