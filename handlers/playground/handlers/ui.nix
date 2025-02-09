# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  callPackage,
  nixpresso,
}:
{
  query,
  uri,
  ...
}:
let
  inherit (builtins)
    elemAt
    filter
    head
    toString
    length
    listToAttrs
    map
    toFile
    toXML
    ;

  inherit (lib)
    generators
    id
    inPureEvalMode
    isFunction
    optionalString
    removeSuffix
    splitString
    ;

  inherit (nixpresso.lib)
    html
    trivial
    handlers
    ;

  expressionString =
    if query ? expression then
      head query.expression
    else if inPureEvalMode then
      ''
        # In pure evaluation mode, we pass the Nixpkgs package set as an argument.
        { pkgs }:
        pkgs.hello.meta
      ''
    else
      ''
        let
            pkgs = import <nixpkgs> { };
        in
        pkgs.hello.meta
      '';

  isEnabled = var: default: if query ? ${var} then head query.${var} == "on" else default;

  raw = isEnabled "raw" false;
  rebuild = isEnabled "rebuild" false;
  recursive = isEnabled "recursive" false;
  pty = isEnabled "pty" false;
  stream = isEnabled "stream" true;

  defaultFormat = "text/nix";

  mode = head (query.mode or [ "serve" ]);
  format = head (query.format or [ defaultFormat ]);
  subPath = head (query.subPath or [ "" ]);
  output = head (query.output or [ "out" ]);

  envString = head (query.env or [ "" ]);
  env =
    let
      allLines = splitString "\n" envString;
      lines = filter (line: line != "") allLines;
      lineToPair =
        fullLine:
        let
          line = removeSuffix ";" fullLine;
          parts = splitString "=" line;
        in
        {
          name = elemAt parts 0;
          value = if length parts >= 2 then elemAt parts 1 else "";
        };
    in
    listToAttrs (map lineToPair lines);

  expressionFile = toFile "expression" expressionString;
  expression = import expressionFile;

  formatter =
    with generators;
    if format == "text/plain" then
      toString
    else if format == "text/nix" then
      toPretty { }
    else if format == "application/json" || format == "application/yaml" then
      toJSON { }
    else if format == "application/xml" then
      toXML
    else
      id;

  result = if isFunction expression then callPackage expression { } else expression;

  resultFormatted = formatter result;

  templateArgs = {
    inherit
      lib

      html
      trivial

      uri

      mode
      format
      raw
      pty
      subPath
      output
      stream
      rebuild
      recursive
      expressionString
      envString
      result
      resultFormatted
      ;
  };

  template = t: import t templateArgs;

  htmlResult = template ../templates/result.nix;
in
if raw then
  {
    body = if mode == "serve" then resultFormatted else result;
    inherit
      mode
      pty
      subPath
      output
      stream
      rebuild
      recursive
      env
      ;
  }
else
  handlers.html {
    title = "Nixpresso Playground";
    bodyClasses = [ "playground" ];

    head = ''
      <style>
        h2 {
          margin-top: 1.5rem;
        }
      </style>
    '';

    main = ''
      ${template ../templates/header.nix}
      ${optionalString (query ? expression) htmlResult}
      ${template ../templates/form.nix}
    '';
  }
