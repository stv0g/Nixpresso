# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  callPackage,
  lib,
  nixpresso,
}:
let
  inherit (builtins)
    readDir
    toFile
    ;
  inherit (lib)
    filterAttrs
    generators
    head
    inPureEvalMode
    isFunction
    optionalString
    readFile
    removeSuffix
    mapAttrs'
    ;
  inherit (nixpresso.lib)
    handlers
    html
    mkHandler
    url
    ;
in
mkHandler
  {
    description = "A Nix and Nixpresso playground";

    pty = true;
  }
  (
    let
      handlerUI =
        {
          method,
          body,
          ...
        }:
        let
          defaultExpression =
            if query ? expr then
              head query.expr
            else if inPureEvalMode then
              ''
                # In pure evaluation moed, we pass the Nixpkgs package set as an argument.
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

          bodyContents = readFile body;
          values = url.decodeQueryString bodyContents;
          exprString = if method == "POST" then values.expression else defaultExpression;
          exprFile = toFile "expression" exprString;
          expr = import exprFile;

          result = if isFunction expr then callPackage expr { } else expr;
          resultPretty = generators.toPretty { } result;

          htmlResult = ''
            <section>
              <h2>Result</h2>
              <pre class="editor"><code>${html.escape resultPretty}</code></pre>
              <button id="permalink">🔗 Permalink</button></a>
            </section>
          '';
        in
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
            ${readFile ./header.html}
            ${optionalString (method == "POST" || query ? e) htmlResult}
            ${readFile ./form.html}
          '';

          script = "<script>${readFile ./script.js}</script>";
        };

      handlerExamples =
        let
          exampleContents = readDir ./examples;
          examplesFiles = filterAttrs (fn: type: type == "regular") exampleContents;
          examples = mapAttrs' (path: _: {
            name = removeSuffix ".nix" path;
            value = readFile (./examples + "/${path}");
          }) examplesFiles;
        in
        {
          body = examples;
          mode = "serve";
        };
    in
    handlers.ifPathEquals "/examples.json" handlerExamples handlerUI
  )
