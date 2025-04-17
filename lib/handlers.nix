# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  status,
  trivial,
}:
let
  inherit (builtins) readDir readFileType toString;
  inherit (lib)
    concatStrings
    concatStringsSep
    functionArgs
    hasPrefix
    hasSuffix
    isDerivation
    isPath
    mapAttrsToList
    match
    mirrorFunctionArgs
    optionalString
    pathExists
    pipe
    removePrefix
    removeSuffix
    reverseList
    ;
  inherit (trivial) updateMeta toFunctor;

  _status = status;

  ifPred =
    pred: matchHandler: fallbackHandler:
    let
      matchHandlerFct = toFunctor matchHandler;
      fallbackHandlerFct = toFunctor fallbackHandler;

      matchHandlerArgs = functionArgs matchHandlerFct;
      fallbackHandlerArgs = functionArgs fallbackHandlerFct;
      predArgs = functionArgs pred;

      matchHandlerMeta = matchHandlerFct.meta or { };
      fallbackHandlerMeta = fallbackHandlerFct.meta or { };

      newArgs = matchHandlerArgs // fallbackHandlerArgs // predArgs;

      handler =
        request:
        let
          requestUpdate = pred request;
          newRequest = request // requestUpdate;

          matchResponse = matchHandlerFct newRequest;
          fallbackResponse = fallbackHandlerFct request;
        in
        if requestUpdate == null then fallbackResponse else matchResponse;
    in
    {
      __functor = _: handler;
      __functionArgs = newArgs;
      meta = updateMeta matchHandlerMeta fallbackHandlerMeta;
    };

  ifPred' = pred: ifPred (mirrorFunctionArgs pred (request: if pred request then { } else null));

  ifPath =
    pred:
    ifPred (
      { path, basePath, ... }:
      let
        newPath = pred path;
      in
      if newPath == null then
        null
      else
        {
          path = newPath;
          basePath = basePath + removeSuffix newPath path;
        }
    );

  ifPathMatch =
    regex:
    ifPred (
      { path, ... }@request:
      let
        matches = match regex path;
      in
      if matches == null then null else request // { inherit matches; }
    );

  ifPathEquals = path: ifPath (p: if path == p then "" else null);

  ifPathHasPrefix =
    prefix: ifPath (path: if hasPrefix prefix path then removePrefix prefix path else null);

  /**
    A simple router that matches the first route that matches the request path.
  */
  router =
    {
      routes,
      defaultHandler ? (htmlError { status = status.notFound; }),
    }:
    pipe defaultHandler (reverseList routes);

  /**
    Render a directory index.
  */
  directoryIndex =
    { fsPath }:
    { path, ... }@request:
    if !hasSuffix "/" path then
      redirect {
        location = "/";
        relative = true;
      } request
    else
      let
        contents = readDir fsPath;
        contentsSuffixed = mapAttrsToList (
          name: type: name + optionalString (type == "directory") "/"
        ) contents;

        tableRows = map (e: ''<tr><td><a href="${e}">${e}</a></td><tr>'') ([ ".." ] ++ contentsSuffixed);
      in
      html {
        title = "Directory Listing";
        main = ''
          <section>
            <p>
              <pre><code>${toString fsPath}</code></pre>
            </p>
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                </tr>
              </thead>
              <tbody>
                ${concatStrings tableRows}
              </tbody>
            </table>
          </section>
        '';
      };

  /**
    Serve a files and/or directories with directory indices.
  */
  servePath =
    { fsPath }:
    assert lib.assertMsg (
      isPath fsPath || isDerivation fsPath || hasPrefix "/nix/store/" fsPath
    ) "fsPath must be a path, a derivation or a store path as a string";
    (
      { path, basePath, ... }:
      let
        subPath = removePrefix basePath path;
        rfsPath = fsPath + subPath;
        fileType = readFileType rfsPath;
      in
      if !pathExists rfsPath then
        htmlError {
          status = status.notFound;
          details = "The following path does not exist: <tt>${rfsPath}</tt>";
        }
      else if fileType == "regular" || fileType == "symlink" then
        {
          body = fsPath;
          inherit subPath;
          mode = "serve";
          type = "path";
        }
      else if fileType == "directory" then
        directoryIndex { fsPath = rfsPath; } { inherit path; }
      else
        htmlError {
          status = status.internalServerError;
          details = "unknown file type: ${fileType}";
        }
    );

  /**
    Render a HTML page.
  */
  html =
    {
      head ? "",
      header ? ''<h1><a href="/"><img class="logo" src="/assets/images/nixpresso-icon.svg" /></a>${title}</h1>'',
      footer ? ''
        <p>Powered by <a href="https://github.com/stv0g/nixpresso"><span class="mdi mdi-nix"></span> Nixpresso</a> from <a href="https://github.com/stv0g">@stv0g</a> &middot; <a href="https://liberapay.com/stv0g/donate"><img alt="Donate using Liberapay" src="/assets/images/donate.svg" /></a></p>
      '',
      bodyClasses ? [ ],
      main ? "",
      title ? "Nixpresso",
      script ? "",
      ...
    }@rest:
    (
      rest
      // {
        headers = (rest.headers or { }) // {
          Content-Type = "text/html; charset=utf-8";
        };

        type = "string";
        mode = "serve";

        body = ''
          <!DOCTYPE html>
          <html lang="en">
            <head>
              <title>${title}</title>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              
              <link rel="stylesheet" href="/assets/bundle.css" rel="stylesheet">
              <link rel="icon" href="/assets/images/nixpresso-favicon.svg" sizes="32x32" type="image/svg+xml" />
              <link rel="apple-touch-icon" href="/assets/images/nixpresso-icon.svg" type="image/svg+xml" />

              ${head}
            </head>
            <body class="${concatStringsSep " " bodyClasses}">
              <header>
                ${header}
              </header>

              <main>
                ${main}
              </main>

              <footer>
                ${footer}
              </footer>

              <script type="module" src="/assets/bundle.js"></script>

              ${script}
            </body>
          </html>'';
      }
    );

  /**
     Render a HTML error page.
  */
  htmlError =
    {
      status ? _status.internalServerError,
      details ? "Sorry, something went wrong.",
    }@rest:
    html (
      rest
      // {
        status = status.code;
        title = "Error";
        main = ''
          <h2>${status.message} (${toString status.code})</h2>
          <p>${details}</p>
        '';
      }
    );

  /**
    Redirect to a different location.
  */
  redirect =
    {
      location,
      status ? _status.movedPermanently,
      relative ? false,
    }:
    { path, basePath, ... }:
    let
      prefix = lib.optionalString relative (basePath + path);
    in
    {
      status = status.code;
      body = "";
      headers = {
        Location = prefix + location;
      };
    };
in
{
  inherit
    ifPred
    ifPred'
    ifPath
    ifPathMatch
    ifPathHasPrefix
    ifPathEquals

    router
    directoryIndex

    servePath
    redirect
    html
    htmlError
    ;
}
