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
        details = "Please send some data via POST.";
        main = ''
          <section>
            <h2>Example</h2>
            <code>echo "Hello world" | curl -v -X POST --data-binary @- http://localhost:8080/run-cat</code>
          </section>

          <section>
            <fieldset role="group">
              <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
              <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/run-cat.nix';"><span class="mdi mdi-github"/> Code</button></a>
            </fieldset>
          <section>
        '';
      }
    else
      {
        body = coreutils;
        subPath = "bin/cat";
        mode = "run";
      }
  )
