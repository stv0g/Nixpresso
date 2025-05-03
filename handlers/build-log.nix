# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ hello, nixpresso }:
let
  inherit (builtins) pathExists;
  inherit (nixpresso.lib) mkHandler handlers;
in
mkHandler { description = "Gets build log of a derivation"; } (
  {
    path,
    meta,
    basePath,
    ...
  }:
  if path == "/log" then
    {
      body = hello;
      mode = "log";

      # Rebuild if it already exists in the store
      # in order to streaming build output in real-time.
      rebuild = pathExists hello.outPath;
    }
  else
    handlers.html {
      title = meta.description;
      main = ''
        <p>
          This example gets the build log of a derivation (or builds it live) and uses <a href="https://xtermjs.org/">Xterm.js</a> to visualize the output.</br >
          For the RAW output, please visit <a href="./log"><code>${basePath}/raw</code></a>.
        </p>

        <pre class="terminal" id="terminal"></pre>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/build-log.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>

        <script type="module">
          import { streamToTerminal } from '/assets/bundle.js';

          document.addEventListener("DOMContentLoaded", async () => {
            const url = new URL(window.location.href);
            url.pathname += "log";
            
            const result = document.getElementById('terminal');

            await streamToTerminal(result.terminal, url.href);
          });
        </script>
      '';
    }
)
