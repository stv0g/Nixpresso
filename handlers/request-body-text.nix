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
      details = ''
        <p>Please pass some payload via a <tt>POST</tt> request:<p>
        <section>
          <h3>Example</h3>
          <code>curl -v ${url.full { inherit host uri tls; }} -d 'Hello world!'</code>
        </section>'';
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
