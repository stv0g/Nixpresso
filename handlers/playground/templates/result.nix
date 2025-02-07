# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  html,
  trivial,

  uri,
  result,
  resultFormatted,
  mode,
  ...
}:
let
  rawUri = uri + "&raw=on";

  resultHtml =
    if mode == "serve" then
      if trivial.isSerializable result then
        ''
          <pre class="editor"><code>${html.escape resultFormatted}</code></pre>
        ''
      else
        ''<a href="${rawUri}"><button>Download</button></a>''
    else if mode == "derivation" then
      ''
        <pre class="editor language-json" id="result"></pre>
        <script type="module">
          document.addEventListener("DOMContentLoaded", async () => {
            const url = new URL(window.location.href);
            url.searchParams.set('raw', 'on');

            const response = await fetch(url.href);
            const result = document.getElementById('result');
            
            result.setValue(await response.text())
          });
        </script>
      ''
    else
      ''
        <pre class="terminal" id="result"></pre>
        <script type="module">
          import { streamToTerminal } from '/assets/bundle.js';

          document.addEventListener("DOMContentLoaded", async () => {
            const url = new URL(window.location.href);
            url.searchParams.set('raw', 'on');
            
            const result = document.getElementById('result');

            await streamToTerminal(result.terminal, url.href);
          });
        </script>
      '';
in
''
  <section>
    <h2>Result</h2>
    ${resultHtml}
    <button id="permalink">🔗 Permalink</button></a>
  </section>
''
