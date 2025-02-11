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
    head
    ;
  inherit (nixpresso.lib)
    mkHandler
    ;

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

  fetchPiperVoice = callPackage ./fetch.nix { };
in
mkHandler
  {
    description = "Synthesize speech from text using piper-tts";
  }
  (
    {
      query,
      ...
    }:
    let
      fetchVoice =
        args:
        fetchPiperVoice (
          args
          // {
            rev = "293cad0539066f86e6bce3b9780c472cc9157489";
            hash = "sha256-HajmnzAvraAQRKVStbKZ+1ZOv/N3ptA3sAFAIoltJBQ=";
          }
        );

      queryDefault = key: default: head (query.${key} or [ default ]);

      key = queryDefault "key" null;
      code = queryDefault "code" null;
      family = queryDefault "family" null;
      name = queryDefault "name" null;
      quality = queryDefault "quality" null;

      voice =
        if key == null && code == null && family == null && name == null then
          fetchVoice {
            code = "en_US";
            quality = "medium";
          }
        else if family != null && thorsten ? ${family} then
          thorsten.${family}
        else
          fetchVoice {
            inherit
              key
              code
              family
              name
              quality
              ;
          };

      defaultText = "Hello world!";
      text = head (query.text or [ defaultText ]);
    in
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
  )
