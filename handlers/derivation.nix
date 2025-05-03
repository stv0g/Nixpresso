# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  lib,
  nixpresso,
}:
let
  inherit (builtins) head;
  inherit (lib) optionalString;
  inherit (nixpresso.lib)
    mkHandler
    handlers
    ;
in
mkHandler
  {
    description = "Get the derivation of a package in JSON format";
  }
  (
    {
      query,
      path,
      meta,
      ...
    }:
    let
      queryDefault = key: default: head (query.${key} or [ default ]);
      packageName = queryDefault "package" "hello";
      recursive = query ? "recursive";

      package = pkgs.${packageName};
    in
    if path == "/raw" then
      {
        body = package;
        mode = "derivation";

        inherit recursive;
      }
    else
      handlers.html {
        title = meta.description;
        main = ''
          <p>
            This example shows the derivation of a package in JSON format. The derivation is taken from Nixpkgs.
            This is roughly equivalent to running <code>nix derivation show nixpkgs#${packageName}</code> on the CLI.
            With the <emph>recursive</emph> option, the derivation's recursive output is returned, which corresponds to the <code>--recursive</code> parameter on the CLI.
          </p>

          <h2>Input</h2>

          <form> 
            <label for="input">
              Package
              <input type="text" id="input" name="package" value="${packageName}" />
            </label>

            <label for="recursive">
              <input type="checkbox" id="recursive" name="recursive" value="true" ${optionalString recursive "checked"} />
              Recursive
            </label>

            <input type="submit" value="Submit" style="margin-top: 2em;" />
          </form>

          <h2>Output</h2>

          <pre id="editor" class="editor language-json"></pre>

          <section>
            <fieldset role="group">
              <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
              <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/derivation.nix';"><span class="mdi mdi-github"/> Code</button></a>
            </fieldset>
          <section>

          <script type="module">
            const form = document.getElementsByTagName('form')[0];

            form.onsubmit = async (e) => {
              e.preventDefault();

              const formData = new FormData(form);
              const params = new URLSearchParams(formData);

              const url = new URL(window.location.href);
              url.pathname += "raw";
              url.search = params.toString();

              const response = await fetch(url.href);
              const text = await response.text();
              const editor = document.getElementById('editor');
              editor.setValue(text);
            }

            document.addEventListener("DOMContentLoaded", form.onsubmit);
          </script>
        '';
      }
  )
