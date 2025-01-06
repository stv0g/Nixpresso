# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  fastfetch,
}:
let
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;
in
mkHandler
  {
    description = "Run fastfetch in a pseudo-terminal (pty)";
  }
  (
    { path, ... }:
    if path == "/run" then
      {
        body = fastfetch;
        subPath = "bin/fastfetch";
        mode = "run";
        pty = true;
      }
    else
      handlers.html {
        title = "Psuedo-terminal";
        main = ''
          <h1>Fastfetch</h1>
          <p>This example runs <a href="https://github.com/fastfetch-cli/fastfetch">fastfetch</a> from Nixpkgs in a pseudo-terminal and uses <a href="https://xtermjs.org/">Xterm.js</a> to visualize the output.</p>
          <pre class="terminal" id="terminal"></pre>
        '';

        script = ''
          <script type="module" >
            import { createTerminal } from '/assets/bundle.js';
            
            document.addEventListener("DOMContentLoaded", async () => {
              let pre = document.getElementById('terminal');
              let response = await fetch('run');
              let out = await response.text();

              pre.terminal.reset();
              pre.terminal.write(out);

              console.log("Fetched")
            });
          </script>
        '';
      }
  )
