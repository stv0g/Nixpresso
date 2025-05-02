# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib, nixpresso }:
let
  inherit (nixpresso.lib) mkHandler;
in
mkHandler { description = "A simple session system"; } (
  {
    headers,
    method,
    body,
    ...
  }:
  let
    inherit (builtins) toFile;
    inherit (lib)
      generators
      inPureEvalMode
      pathExists
      readFile
      removeAttrs
      ;
    inherit (nixpresso.lib)
      cookie
      handlers
      html
      status
      url
      ;

    cookies = cookie.parse headers;

    oldSession =
      if cookies ? session && pathExists cookies.session then
        import cookies.session
      else
        { counter = 0; };

    newSession = update oldSession;
    newSessionFile = toFile "session" (generators.toPretty { } newSession);

    prettyNewSession = generators.toPretty { } newSession;

    update =
      old:
      if method == "POST" then
        let
          bodyContents = readFile body;
          values = url.decodeQueryString bodyContents;

          inherit (values) action key value;
        in
        if action == "Add" then
          old
          // {
            ${key} = value;
            counter = old.counter + 1;
          }
        else if action == "Remove" then
          removeAttrs old [ key ] // { counter = old.counter + 1; }
        else if action == "Reset" then
          { counter = 0; }
        else
          old // { counter = old.counter + 1; }
      else
        old // { counter = old.counter + 1; };
  in
  if inPureEvalMode then
    handlers.htmlError {
      status = status.serviceUnavailable;
      details = "The session handler example requires impure evaluation mode.";
    }
  else
    handlers.html {
      title = "Session Demo";
      main = ''
          <p>This example demonstrates how we can store session data in the Nix store and load it from a Cookie.</p>
          <section>
            <h2>Session Data</h2>
            <pre class="editor"><code>${html.escape prettyNewSession}</code></pre>
          </section>

          <section>
            <h2>Update Session</h2>
            <form method="post">
              <fieldset>
                <label>
                  Key
                  <input
                    name="key"
                    value="hello"
                  />
                </label>
                <label>
                  Value
                  <input
                    name="value"
                    value="world"
                  />
                </label>
              </fieldset>

              <div role="group">
                <input type="submit" name="action" value="Add" />
                <input type="submit" name="action" value="Remove" class="secondary" />
                <input type="submit" name="action" value="Reset" class="contrast" />
              </div>
            </form>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/session.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';

      headers = {
        Set-Cookie = "session=${newSessionFile}";
      };
    }
)
