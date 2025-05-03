# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  writeText,
  runCommandNoCC,
  texliveSmall,
}:
let
  inherit (builtins)
    head
    readFile
    ;
  inherit (nixpresso.lib)
    mkHandler
    html
    url
    handlers
    ;

  texlive = texliveSmall.withPackages (
    ps: with ps; [
      standalone
      pgf-blur
    ]
  );
in
mkHandler
  {
    description = "Render a LaTeX document";
  }
  (
    {
      path,
      meta,
      query,
      basePath,
      ...
    }:
    let
      queryDefault = key: default: head (query.${key} or [ default ]);

      document = queryDefault "document" (readFile ./document.tex);
      documentFile = writeText "document.tex" document;
    in
    if path == "/raw" then
      {
        body =
          runCommandNoCC "document.pdf"
            {
              buildInputs = [ texlive ];
            }
            ''
              xelatex ${documentFile}
              mv *-document.pdf $out
            '';

        headers = {
          "Content-Type" = "application/pdf";
        };
      }
    else
      handlers.html {
        title = meta.description;
        main = ''
          <p>
            This example builds a LaTeX document using <a href="https://xetex.sourceforge.net/">XeTeX</a> and <a href="https://www.tug.org/texlive/">TeX Live</a>.
            A PDF document is generated from the LaTeX source code via the <a href="${basePath}/raw"><code>${basePath}/raw</code></a> endpoint.
            The document which should be rendered is passed as a query parameter <code>document</code>.
          </p>

          <h2>Input</h2>

          <form method="get" action=".">
            <label for="input">LaTeX Document
              <textarea class="editor language-latex" name="document" rows="15" cols="50">${html.escape document}</textarea>
            </label>

            <input type="submit" value="Render">
          </form>

          <h2>Output</h2>

          <center>
            <embed src="./raw?document=${url.escape document}#toolbar=0&navpanes=0" style="width: 50%; height: 900px; margin-bottom: 3em;" />
          </center>

          <section>
            <fieldset role="group">
              <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
              <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/run-pty.nix';"><span class="mdi mdi-github"/> Code</button></a>
            </fieldset>
          <section>
        '';
      }
  )
