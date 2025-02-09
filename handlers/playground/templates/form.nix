# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  mode,
  pty,
  raw,
  stream,
  rebuild,
  recursive,
  format,
  output,
  subPath,
  expressionString,
  envString,
  ...
}:
let
  inherit (lib)
    optionalString
    concatStringsSep
    ;

  option = s: o: description: ''
    <option value="${o}" ${optionalString (s == o) "selected"}>${description}</option>
  '';

  optionMode = option mode;
  optionFormat = option format;

  switch = name: label: checked: classes: ''
    <label class="${concatStringsSep " " classes}">
      <input type="checkbox" name="${name}" id="${name}" ${optionalString checked "checked"} role="switch" />
      ${label}
    </label>
  '';
in
''
  <section>
    <form>
      <h2>Expression</h2>
      <fieldset>
        <label>Example
          <select name="example" aria-label="Choose an example...">
            <option selected disabled>Please choose an example from the list...</option>
          </select>
        </label>
        <label>Expression
          <textarea class="editor language-nix" rows=10 name="expression">${expressionString}</textarea>
        </label>
      </fieldset>
      <h2>Options</h2>
      <fieldset>
        <div class="grid">
          <div>
            <label>Mode
              <select name="mode" aria-label="Select the evaluation mode..." required>
                ${optionMode "serve" "Serve result"}
                ${optionMode "run" "Run result"}
                ${optionMode "log" "Get build log of realization"}
                ${optionMode "derivation" "Get derivation as JSON"}
              </select>
            </label>
            <label class="mode mode-serve mode-derivation">Format
              <select name="format" aria-label="Select the output format..." required>
                ${optionFormat "text/nix" "Nix"}
                ${optionFormat "text/plain" "Plain text"}
                ${optionFormat "application/json" "JSON"}
                ${optionFormat "application/yaml" "YAML"}
                ${optionFormat "application/xml" "XML"}
              </select>
            </label>
            ${switch "stream" "Stream output" stream [
              "mode"
              "mode-run"
              "mode-log"
              "mode-derivation"
            ]}
            ${switch "raw" "Raw output" raw [ ]}
            ${switch "rebuild" "Rebuild derivation" rebuild [ ]}
            ${switch "recursive" "Recursive" recursive [
              "mode"
              "mode-derivation"
            ]}
            ${switch "pty" "Pseudo Terminal (PTY)" pty [
              "mode"
              "mode-run"
            ]}
          </div>
          <div>
            <label class="mode mode-run mode-serve">
              Derivation output
              <input type="text" name="output" value="${output}" />
            </label>
            <label class="mode mode-run mode-serve">
              Derivation sub-path
              <input type="text" name="subPath" value="${subPath}" />
            </label>
            <label class="mode mode-run">
              Environment variables
              <textarea name="env" placeholder="MYVAR=myvalue&#10;LANG=en_US.UTF-8">${envString}</textarea>
            </label>
          </div>
        </div>
      </fieldset>

      <div role="group">
        <button type="submit">
          Evaluate&emsp;<kbd>Ctrl</kbd> + <kbd>&crarr;</kbd>
        </button>
        <button onclick="history.back()">Back</button>
      </div>
    </form>
  </section>
''
