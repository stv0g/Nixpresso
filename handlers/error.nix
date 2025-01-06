# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
}:
let
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;
in
mkHandler
  {
    description = "Nixpresso Error Handler";
  }
  (
    handlers.htmlError {
      details = ''
        <section id="error">
          <h2>Error Output</h2>
          <pre class="editor"><code>{{ .StderrPretty }}</code></pre>
        </section>

        <section id="request">
          <h2>Request</h2>

          <h3>Installable</h3>
          <pre class="language-text no-line-numbers"><code>{{ .Installable }}</code></pre>

          <h3>Command Line</h3>
          <pre class="language-text"><code class="no-line-numbers language-shell">{{ .CmdLinePretty  }}</code></pre>
        </section>
      '';
    }
  )
