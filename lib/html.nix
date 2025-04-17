# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (lib) replaceStrings attrNames attrValues;

  entityTable = {
    "<" = "lt";
    ">" = "gt";
    "&" = "amp";
    "\"" = "quot";
    "'" = "#39";
  };

  codes = map (e: "&${e};") (attrValues entityTable);
  chars = attrNames entityTable;

  escape = s: replaceStrings chars codes s;
  unescape = s: replaceStrings codes chars s;
in
{
  inherit escape unescape;
}
