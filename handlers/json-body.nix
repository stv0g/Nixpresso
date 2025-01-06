{
  handlerFile,
  method,
  uri,
  headers,
  body,
  ...
}@request:
let
  inherit (builtins) fromJSON;

  bodyJSON = fromJSON body;
in
{
  status = 200;
  headers = {
    "Content-type" = "application/json";
  };

  body = bodyJSON // request;

  stream = false; # Runs body derivation instead of building it
  sandbox = false; # Enables __noChroot
}
