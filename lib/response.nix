# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  status,
  trivial,
  handlers,
  html,
}:
let
  inherit (builtins)
    fetchurl
    hashString
    path
    toJSON
    head
    ;
  inherit (lib)
    concatStringsSep
    elem
    functionArgs
    getAttrs
    inPureEvalMode
    isDerivation
    isPath
    isStorePath
    isString
    mapAttrs
    optional
    optionalAttrs
    optionals
    optionalString
    pipe
    recursiveUpdate
    splitString
    toList
    trim
    typeOf
    ;
  inherit (trivial)
    updateHandler
    updateMeta
    isSerializable
    toFunctor
    ;
  inherit (handlers)
    htmlError
    ;

  responseDefaults = {
    status = status.ok.code;
    body = "";
    mode = "serve";
    output = "out";
    headers = { };
    subPath = "";
    args = [ ];
    env = { };
    rebuild = false;
    recursive = false;
    pty = false;
    stream = true;
  };

  metaDefaults = {
    evalCacheIgnore = {
      headers = [ ];

      args = [
        "remoteAddr"
      ];
    };

    evalArgs = [ ];
  };

  withResponseDefaults =
    handler:
    updateHandler handler (
      request:
      let
        response = handler request;
      in
      responseDefaults // response
    );

  withMetaDefaults =
    metaExtra: handler:
    let
      metaHandler = handler.meta or { };
    in
    (
      handler
      // {
        meta = updateMeta metaHandler (updateMeta metaDefaults metaExtra);
      }
    );

  checkModeType =
    handler:
    updateHandler handler (
      { options, ... }@request:
      let
        response = handler request;
      in
      if !elem response.mode options.allowedModes then
        handlers.htmlError {
          status = status.serviceUnavailable;
          details = ''
            This handler requires the ${response.mode} mode.
          '';
        }
      else if !elem response.type options.allowedTypes then
        handlers.htmlError {
          status = status.serviceUnavailable;
          details = ''
            This handler requires the ${response.type} type.
          '';
        }
      else
        response
    );

  withRequestBodyDrv =
    handler:
    let
      args = functionArgs handler;

      handlerWithBody =
        {
          bodyHash,
          ...
        }@request:
        let
          bodyDrv = fetchurl {
            name = "body";
            url = "file:///dev/stdin";
            sha256 = bodyHash;
          };

          requestWithBody = request // {
            body = bodyDrv;
          };
        in
        handler requestWithBody;
    in
    if args ? body then updateHandler handler handlerWithBody else handler;

  checkCacheHeaders =
    handler:
    updateHandler handler (
      request:
      let
        responseUncached = handler request;

        responseETag = responseUncached.headers.ETag or null;
        requestETag = request.headers.If-None-Match or null;

        isCached = responseETag != null && requestETag != null && responseETag == requestETag;

        responseCached = responseDefaults // {
          status = status.notModified.code;
        };
      in
      if isCached then responseCached else responseUncached
    );

  withCacheHeaders =
    handlerFn:
    updateHandler handlerFn (
      { options, ... }@request:
      let
        response = handlerFn request;
        meta = handlerFn.meta or { };

        headersCachable = getAttrs (meta.cacheHeaders or [ ]) request.headers;
        requestCachable = getAttrs (meta.cacheArgs or [ ]) (
          request
          // {
            headers = headersCachable;
          }
        );
        cachable = {
          inherit requestCachable;
          inherit options;
        };

        headersCaching = {
          Cache-Control = "public, max-age=86400, must-revalidate";
          ETag = hashString "sha256" (toJSON cachable);
        };
      in
      response
      // {
        headers = headersCaching // response.headers;
      }
    );

  fixupResponseBodyType =
    handler:
    updateHandler handler (
      request:
      let
        response = handler request;

        inherit (response) body;

        responseFixup = (
          if !response ? body || response ? type then
            { } # No body, or type already set
          else if isDerivation body then
            {
              body = body.drvPath;
              type = "derivation";
            }
          else if isPath body then
            {
              type = "path";
            }
            // (optionalAttrs (isStorePath body) {
              body = path body;
            })
          else if isString body then
            {
              type = "string";
              headers = {
                Content-type = "text/plain; charset=utf-8";
              };
            }
          else if isSerializable body then
            {
              body = toJSON body;
              type = "string";
              headers = {
                Content-type = "application/json; charset=utf-8";
              };
            }
          else
            throw "Invalid response body type: ${typeOf body}"
        );
      in
      response // responseFixup
    );

  setNixHeader =
    handlerFn:
    updateHandler handlerFn (
      request:
      let
        response = handlerFn request;
        headerComponents =
          with response;
          (
            [
              "type=${type}"
              "mode=${mode}"
            ]
            ++ optional pty "pty"
            ++ optional inPureEvalMode "pure"
            ++ optional (!inPureEvalMode) "system=${builtins.currentSystem}"
            ++ optional (mode == "derivation" && recursive) "recursive"
            ++ optional (type == "derivation" && (mode == "log" || mode == "serve") && rebuild) "rebuild"
            ++ optionals (type == "derivation") [
              "output=${output}"
            ]
            ++ optional (type == "path" || type == "derivation") "path=${body}"
            ++ optional (subPath != "") "subPath=${subPath}"
          );
      in
      recursiveUpdate response {
        headers = {
          Nix = concatStringsSep ", " headerComponents;
        };
      }
    );

  fixupResponseHeaders =
    handler:
    updateHandler handler (
      request:
      let
        response = handler request;
      in
      response
      // {
        headers = mapAttrs (_: v: toList v) response.headers;
      }
    );

  handleError =
    handler:
    updateHandler handler (
      { error, headers, ... }@request:
      let
        isError = error != null;
        accepts = map trim (splitString "," (head (headers.Accept or [ "" ])));
        acceptsHTML = elem "text/html" accepts;
      in
      if isError then
        (
          responseDefaults
          // (
            if acceptsHTML then
              htmlError {
                status = status.internalServerError;
                details = ''
                  <p>An error occurred:</p>
                  <pre class="error"><code>${error.error}</code></pre>
                  ${optionalString (
                    error ? stdout
                  ) "<pre class=\"terminal\"><code>${html.escape error.stdout}</code></pre>"}
                  ${optionalString (
                    error ? stderr
                  ) "<pre class=\"terminal\"><code>${html.escape error.stderr}</code></pre>"}
                '';
              }
            else
              {
                body = ''
                  An error occurred:
                  ${error.error}
                  ${optionalString (error ? stdout) "stdout: ${error.stdout}"}
                  ${optionalString (error ? stderr) "stderr: ${error.stderr}"}
                '';
              }
          )
        )
      else
        handler request
    );

  /**
    Create a new handler.
  */
  mkHandler =
    meta: handler:
    pipe handler [
      toFunctor
      withResponseDefaults
      (withMetaDefaults meta)
      withRequestBodyDrv
      checkCacheHeaders
      withCacheHeaders
      handleError
      fixupResponseBodyType
      checkModeType
      setNixHeader
      fixupResponseHeaders
    ];
in
{
  inherit mkHandler;
}
