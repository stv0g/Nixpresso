# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib, nixpresso }:
let
  inherit (lib)
    concatStrings
    elemAt
    generators
    map
    ;
  inherit (nixpresso.lib) status mkHandler;
  inherit (nixpresso.lib.handlers)
    htmlError
    html
    router
    ifPathMatch
    ifPathEquals
    ifPathHasPrefix
    ifPred
    ;

  personData = {
    stv0g = {
      address = "Somewhere in the world";
      phone = "+49 123 456789";
    };
    louis = {
      address = "Somewhere else";
      phone = "+49 987 654321";
    };
  };

  handlerPersonFound =
    {
      person,
      resource,
      result,
      ...
    }:
    html {
      main = ''
        <section>
          <h2>Its a match!</h2>
          <dl>
            <dt><strong>person</strong></dt>
            <dd>${person}</dd>

            <dt><strong>${resource}</strong></dt>
            <dd>${result}</dd>
          </dl>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/router.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';
    };

  handlerPersonQuery = ifPred (
    { matches, ... }:
    let
      person = elemAt matches 0;
      resource = elemAt matches 1;
      result = personData.${person}.${resource} or null;
    in
    if result != null then { inherit person resource result; } else null
  ) handlerPersonFound handlerNotFound;

  handlerPerson = router {
    routes = [
      (ifPathEquals "/" handlerPersonHelp)
      (ifPathMatch "/([^/]+)/(address|phone)" handlerPersonQuery)
    ];
    defaultHandler = handlerNotFound;
  };

  handlerQuery =
    { query, ... }:
    html {
      title = "Query based routing";
      main = ''
        <section>
          <h2>Query based routing</h2>
          <p>Query: ${generators.toPretty { } query}</p>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/router.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';
    };

  handlerExamples =
    examples:
    { basePath, ... }:
    html {
      title = "Predicate based routing";
      main = ''
        <p>
          This example demonstrates how to route requests based on predicates.
          Please use one of the following URIs to see the handler in action.
        </p>
        <section>
          <h2>Examples</h2>
          <ul>
            ${concatStrings (map (e: ''<li><a href="${basePath}${e}">${basePath}${e}</a></li>'') examples)}
          </ul>
        </section>

        <section>
          <fieldset role="group">
            <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
            <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/blob/main/handlers/router.nix';"><span class="mdi mdi-github"/> Code</button></a>
          </fieldset>
        <section>
      '';
    };

  handlerHelp = handlerExamples [
    "person/"
    "?key=value"
  ];

  handlerPersonHelp = handlerExamples [
    "stv0g/address"
    "louis/phone"
  ];

  handlerNotFound = htmlError {
    status = status.notFound;
    details = ''
      <section>
        <fieldset role="group">
          <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
          <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/tree/main/handlers/router.nix';"><span class="mdi mdi-github""/> Code</button></a>
        </fieldset>
      </section>
    '';
  };

  hasQueryArgs = { query, ... }: if query != { } then { } else null;
in
mkHandler { description = "Predicate based routing"; } (router {
  routes = [
    (ifPred hasQueryArgs handlerQuery)
    (ifPathEquals "/" handlerHelp)
    (ifPathHasPrefix "/person" handlerPerson)
  ];
  defaultHandler = handlerNotFound;
})
