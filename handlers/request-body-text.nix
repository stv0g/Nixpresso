# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ nixpresso }:
let
  inherit (builtins) readFile;
  inherit (nixpresso.lib)
    handlers
    mkHandler
    status
    url
    ;
in
mkHandler { description = "Return raw request payload in body"; } (
  {
    body,
    method,
    uri,
    host,
    tls,
    ...
  }:
  let
    bodyRaw = readFile body;
  in
  if method != "POST" then
    handlers.htmlError {
      status = status.methodNotAllowed;
      details = "Please pass some payload via a <tt>POST</tt> request.";
      main = ''
        <section>
          <h2>Example</h2>
          <code>curl -v ${url.full { inherit host uri tls; }} -d 'Hello world!'</code>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/request-body-text.nix';"><span class="mdi mdi-github"/> Code</button></a>
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
    {
      inherit body;
      type = "path";
    }
)
