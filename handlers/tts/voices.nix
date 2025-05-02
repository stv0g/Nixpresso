# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  callPackage,
  fetchurl,
}:
let
  inherit (builtins)
    readFile
    fromJSON
    baseNameOf
    filter
    head
    sort
    ;

  inherit (lib) mapAttrs mapAttrsToList concatStringsSep;

  inherit (lib.lists) findFirstIndex;

  fetchurlLegacy = callPackage ./fetchurl-legacy.nix { };

  voicesFile =
    let
      rev = "293cad0539066f86e6bce3b9780c472cc9157489";
      hash = "sha256-HajmnzAvraAQRKVStbKZ+1ZOv/N3ptA3sAFAIoltJBQ=";
    in
    fetchurl {
      url = "https://huggingface.co/rhasspy/piper-voices/raw/${rev}/voices.json";
      inherit hash;
    };

  voicesJSON = readFile voicesFile;
  voices = fromJSON voicesJSON;
  voicesList = mapAttrsToList (_: voice: voice) voices;

  fetch =
    {
      key ? "en_US-amy-medium",
      name ? null,
      code ? null,
      family ? null,
      quality ? null,
    }:
    let

      qualities = [
        "x_low"
        "low"
        "medium"
        "high"
      ];

      voiceQuality = voice: findFirstIndex (q: q == voice.quality) (-1) qualities;
      sortByQuality = sort (a: b: voiceQuality a < voiceQuality b);

      voice =
        if name == null && code == null && family == null && quality == null then
          voices.${key}
        else
          head (
            sortByQuality (
              filter (
                voice:
                (name == null || voice.name == name)
                && (quality == null || voice.quality == quality)
                && (code == null || voice.language.code == code)
                && (family == null || voice.language.family == family)
              ) voicesList
            )
          );

      drvs = mapAttrs (
        name: file:
        fetchurlLegacy {
          name = baseNameOf name;
          url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/${name}?download=true";
          hash = file.md5_digest;
        }
      ) voice.files;

      base = concatStringsSep "/" [
        voice.language.family
        voice.language.code
        voice.name
        voice.quality
        voice.key
      ];
    in
    {
      model = drvs."${base}.onnx";
      config = drvs."${base}.onnx.json";
    };
in
{
  inherit fetch voices;
}
