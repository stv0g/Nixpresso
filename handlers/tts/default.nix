# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  nixpresso,
  piper-tts,
  runCommandNoCC,
  callPackage,
  fetchurl,
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    groupBy
    head
    mapAttrsToList
    ;
  inherit (nixpresso.lib) handlers url mkHandler;

  thorsten = {
    hessisch = {
      model = fetchurl {
        url = "https://huggingface.co/Thorsten-Voice/Hessisch/resolve/main/Thorsten-Voice_Hessisch_Piper_high-Oct2023.onnx";
        hash = "sha256-Q/tDd26Ru4HjWwsvUOCUtNNQqj+Qysifx8L97LdVThU= ";
      };

      config = fetchurl {
        url = "https://huggingface.co/Thorsten-Voice/Hessisch/resolve/main/Thorsten-Voice_Hessisch_Piper_high-Oct2023.onnx.json";
        hash = "sha256-SjFVp883PsA4Ym/RCvOKStuJuE5zG2Ypdhn1Esya2sM=";
      };
    };
  };

  voices = callPackage ./voices.nix { };
in
mkHandler { description = "Synthesize speech from text using piper-tts"; } (
  {
    query,
    path,
    meta,
    ...
  }:
  let
    queryDefault = key: default: head (query.${key} or [ default ]);

    key = queryDefault "key" "en_US-amy-medium";
    code = queryDefault "code" null;
    family = queryDefault "family" null;
    name = queryDefault "name" null;
    quality = queryDefault "quality" null;
    text = queryDefault "text" "Hello world!";

    voice =
      if family != null && thorsten ? ${family} then
        thorsten.${family}
      else
        voices.fetch {
          inherit
            key
            code
            family
            name
            quality
            ;
        };

    audioQuery = url.encodeQueryString (
      filterAttrs (_: v: v != null) {
        inherit
          key
          code
          family
          name
          quality
          text
          ;
      }
    );
  in
  if path == "/audio" then
    {
      body = runCommandNoCC "tts.wav" { } ''
        echo "${text}" | ${piper-tts}/bin/piper \
          --quiet \
          --output_file - \
          --model ${voice.model} \
          --config ${voice.config} > $out
      '';

      headers = {
        "Content-Type" = "audio/wav";
      };
    }
  else
    handlers.html {
      title = meta.description;
      main = ''
        <p>
          This example uses <a href="https://github.com/rhasspy/piper">piper TTS</a> to synthesize speech from text.
        </p>

        <section>
          <h2>Input</h2>
          <form>
            <label>Text
              <textarea class="editor" rows=10 name="text">${text}</textarea>
            </label>
            <label>Voice
              <select name="key">
                ${concatStringsSep "\n" (
                  mapAttrsToList
                    (language: voices: ''
                      <optgroup label="${language}">
                        ${concatStringsSep "\n" (
                          map (
                            voice:
                            ''<option value="${voice.key}" ${
                              if key == voice.key then "selected" else ""
                            }>${voice.name} ${voice.quality}</option>''
                          ) voices
                        )}
                      </optgroup>
                    '')
                    (
                      groupBy (v: "${v.language.name_english} [${v.language.code}]") (
                        mapAttrsToList (n: v: v) voices.voices
                      )
                    )
                )}
              </select>
            </label>
            <button type="submit" /><span class="mdi mdi-play" /> Text-to-Speech</button>
          </form>
        </section>

        <section>
          <h2>Output</h2>
          <center>
            <audio src="audio?${audioQuery}" autoplay controls style="margin-bottom: 3em;" />
          </center>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/tree/main/handlers/tts';"><span class="mdi mdi-github""/> Code</button></a>
          </fieldset>
        </section>
      '';
    }
)
