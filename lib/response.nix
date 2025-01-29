# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  status,
  trivial,
  handlers,
}:
let
  inherit (builtins)
    fetchurl
    hashString
    path
    toJSON
    ;
  inherit (lib)
    concatStringsSep
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
    pipe
    recursiveUpdate
    toList
    typeOf
    ;
  inherit (trivial)
    updateHandler
    isJSONSerializable
    toFunctor
    ;
  inherit (handlers)
    htmlErrorEval
    ifPred'
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
    cacheHeaders = [
      "If-None-Match"
      "Pragma"
      "Cache-Control"
    ];

    cacheArgs = [
      "remoteAddr"
    ];

    evalArgs = [ ];
  };

  setResponseDefaults =
    handler:
    updateHandler handler (
      request:
      let
        response = handler request;
      in
      responseDefaults // response
    );

  setMetaDefaults =
    meta: handler:
    (
      handler
      // {
        meta = metaDefaults // (handler.meta or { }) // meta;
      }
    );

  passRequestBodyAsDrv =
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

  setCacheHeaders =
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
          else if isJSONSerializable body then
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

  handleError = ifPred' ({ error, ... }: error != null) htmlErrorEval;
in
{
  /**
    Create a new handler.
  */
  mkHandler =
    meta: handler:
    pipe handler [
      toFunctor
      setResponseDefaults
      (setMetaDefaults meta)
      passRequestBodyAsDrv
      checkCacheHeaders
      setCacheHeaders
      fixupResponseBodyType
      setNixHeader
      handleError
      fixupResponseHeaders
    ];
}
