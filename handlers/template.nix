# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib, nixpresso }:
let
  inherit (nixpresso.lib) handlers html mkHandler;
in
mkHandler { description = "Render an HTML template with all request data"; } (
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
    meta,
    tls,
    ...
  }@request:
  let
    prettyRequest = lib.generators.toPretty { } request;
  in
  handlers.html {
    title = meta.description;
    main = ''
      <p>
        This example renders an HTML template with all request data.
      </p>

      <section>
        <h2>Request</h2>
        <pre class="editor"><code>${html.escape prettyRequest}</code></pre>
      </section>

      <section>
        <fieldset role="group">
          <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
          <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/template.nix';"><span class="mdi mdi-github"/> Code</button></a>
        </fieldset>
      <section>
    '';
  }
)
