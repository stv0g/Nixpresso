# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  nixpresso,
}:
let
  inherit (lib)
    concatStrings
    elem
    filterAttrs
    mapAttrsToList
    removeSuffix
    ;
  inherit (nixpresso.lib)
    handlers
    mkHandler
    ;

  homeHandlers = filterAttrs (
    name: _:
    !elem name [
      "default"
      "override"
      "overrideDerivation"
    ]
  ) nixpresso.handlers;

  rows = mapAttrsToList (
    name: handler:
    let
      link = removeSuffix ".nix" name;
    in
    ''
      <tr>
        <td><a href="/${link}/">${name}</a></td>
        <td>${handler.meta.description or ""}</td>
      </tr>''
  ) homeHandlers;
in
mkHandler
  {
    description = "Home page";
  }
  (
    handlers.html {
      title = "Nixpresso - Expressions served hot!";
      header = ''
        <img class="banner" src="/assets/images/nixpresso-banner.svg" alt="Nixpresso logo" />

        <div class="badges">
          <a href="https://github.com/stv0g/nixpresso"><img src="https://img.shields.io/github/stars/stv0g/nixpresso?style=flat-square&logo=github" alt="GitHub stars"></a>
          <a href="https://github.com/stv0g/nixpresso/actions"><img src="https://img.shields.io/github/actions/workflow/status/stv0g/nixpresso/build.yaml?style=flat-square" alt="GitHub build"></a>
          <a href="https://goreportcard.com/report/github.com/stv0g/nixpresso"><img src="https://goreportcard.com/badge/github.com/stv0g/nixpresso?style=flat-square" alt="goreportcard"></a>
          <a href="https://app.codecov.io/gh/stv0g/nixpresso"><img src="https://img.shields.io/codecov/c/github/stv0g/nixpresso?token=WWQ6SR16LA&style=flat-square" alt="Codecov"></a>
          <a href="https://github.com/stv0g/nixpresso/blob/main/LICENSE"><img src="https://img.shields.io/github/license/stv0g/nixpresso?style=flat-square" alt="License"></a>
          <img src="https://img.shields.io/github/go-mod/go-version/stv0g/nixpresso?style=flat-square&logo=go" alt="GitHub go.mod Go version">
          <a href="https://pkg.go.dev/github.com/stv0g/nixpresso"><img src="https://pkg.go.dev/badge/github.com/stv0g/nixpresso.svg" alt="Go Reference"></a>
          <a href="code_of_conduct.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg?style=flat-square" alt="Contributor Covenant"></a>
          <a href="https://liberapay.com/stv0g/donate"><img src="https://img.shields.io/liberapay/receives/stv0g.svg?logo=liberapay&style=flat-square" alt="Liberay Pay funding"></a>
        </div>
      '';
      bodyClasses = [ "home" ];
      main = ''
        <section>
          <h1>Welcome to Nixpresso!</h1>
          <p>
            Nixpresso is a HTTP server delegating request handling to a Nix function:
          </p>

          <pre class="editor"><code>{
            query ? { user = "stv0g"; }
        }: {
            body = "Hello ''${query.user}";
        }</code></pre>

          <p>
            Nixpresso's HTTP server is written in Go, while as much as possible of request handling is implemented in Nix.
            Nixpresso uses the <a href="https://github.com/NixOS/nix">NixCpp</a> evaluator and store for serving evaluated Nix expressions, build outputs, build logs, derivations or runs executables in a CGI-fashion.
          </p>

          <p>
            While probably not a good idea, Nixpresso could be used to build fully featured web-applications including supportrequest/response streaming, session stores, authentication and much more.
          </p>
        </section>
        <section>
          <h2>Playground</h2>
          <p>
            Have a look at the playground to see all features in action.
          </p>
          <center>
            <a href="/playground/"><button class="large contrast">Go to Playground 🎲</button></a>
          </center>
        </section>
        <section>
          <h2>Available handlers</h2>
          <p>Click on a handler to see more details.</p>
          <table>
            <thead>
              <tr>
                <th>Handler</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              ${concatStrings rows}
            </tbody>
          </table>
        </section>'';
    }
  )
