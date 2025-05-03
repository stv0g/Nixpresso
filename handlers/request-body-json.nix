# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ nixpresso }:
let
  inherit (builtins) fromJSON readFile;
  inherit (nixpresso.lib)
    handlers
    mkHandler
    status
    url
    ;
in
mkHandler { description = "Return JSON request payload a JSON response"; } (
  {
    body,
    method,
    host,
    uri,
    tls,
    ...
  }:
  let
    bodyRaw = readFile body;
  in
  if method != "POST" then
    handlers.htmlError {
      status = status.methodNotAllowed;
      details = "Please pass some JSON encoded payload via a <tt>POST</tt> request.";
      main = ''
        <section>
          <h2>Example</h2>
          <code>curl -v ${url.full { inherit host uri tls; }} -d '{"some": "value"}'</code>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/request-body-json.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';
    }
  else if bodyRaw == "" then
    handlers.htmlError {
      status = status.badRequest;
      details = "No or malformed body passed";
    }
  else
    { body = fromJSON bodyRaw; }
)
