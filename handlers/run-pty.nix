# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  fastfetch,
}:
let
  inherit (nixpresso.lib) handlers mkHandler;
in
mkHandler { description = "Run fastfetch in a pseudo-terminal (pty)"; } (
  { path, meta, ... }:
  if path == "/run" then
    {
      body = fastfetch;
      subPath = "bin/fastfetch";
      mode = "run";
      pty = true;
    }
  else
    handlers.html {
      title = meta.description;
      main = ''
        <p>
          This example runs <a href="https://github.com/fastfetch-cli/fastfetch">fastfetch</a> from Nixpkgs in a pseudo-terminal and uses <a href="https://xtermjs.org/">Xterm.js</a> to visualize the output.
        </p>

        <pre class="terminal" id="terminal"></pre>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/run-pty.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>

        <script type="module">
          import { streamToTerminal } from '/assets/bundle.js';

          document.addEventListener("DOMContentLoaded", async () =>  {
              const url = new URL(window.location.href);
              url.pathname += "run";
              
              const terminal = document.getElementById('terminal');
              await streamToTerminal(terminal.terminal, url.href);
          })
        </script>
      '';
    }
)
