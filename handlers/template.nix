# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  nixpresso,
}:
let
  inherit (nixpresso.lib)
    handlers
    html
    mkHandler
    ;
in
mkHandler
  {
    description = "Render an HTML template with all request data";
  }
  (
    {
      # deadnix: skip
      proto, # deadnix: skip
      method, # deadnix: skip
      uri, # deadnix: skip
      headers, # deadnix: skip
      query, # deadnix: skip
      path, # deadnix: skip
      basePath, # deadnix: skip
      host, # deadnix: skip
      remoteAddr, # deadnix: skip
      bodyHash, # deadnix: skip
      body, # deadnix: skip
      options, # deadnix: skip
      tls,
      ...
    }@request:
    let
      prettyRequest = lib.generators.toPretty { } request;
    in
    handlers.html {
      title = "Nix-based templating";
      main = ''
        <section>
          <h2>Request</h2>
          <pre class="editor"><code>${html.escape prettyRequest}</code></pre>
        </section>

        <section>
          <button onclick="history.back()">Back</button>
        </section>
      '';
    }
  )
