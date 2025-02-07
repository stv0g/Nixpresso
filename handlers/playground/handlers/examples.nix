# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (builtins)
    readDir
    readFile
    pathExists
    ;

  inherit (lib)
    filterAttrs
    hasSuffix
    inPureEvalMode
    mapAttrs'
    removeSuffix
    ;

  exampleContents = readDir ../examples;
  examplesFiles = filterAttrs (
    fn: type: type == "regular" && hasSuffix ".nix" fn && !hasSuffix ".meta.nix" fn
  ) exampleContents;
  examples = mapAttrs' (
    codeFile: _:
    let
      name = removeSuffix ".nix" codeFile;

      codePath = ../examples + "/${name}.nix";
      metaPath = ../examples + "/${name}.meta.nix";

      meta = if pathExists metaPath then import metaPath else { };
    in
    {
      inherit name;
      value = meta // {
        code = readFile codePath;
      };
    }
  ) examplesFiles;

  examplesCompatible = filterAttrs (
    name: example: !inPureEvalMode || !(example.impure or false)
  ) examples;
in
{
  body = examplesCompatible;
  mode = "serve";
}
