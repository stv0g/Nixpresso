{
  method,
  uri,
  headers,
  body,
  ...
}@request:
let
  pkgs = import <nixpkgs> { };
  web = import ./web-lib.nix pkgs;

  query = web.queryArgs uri;
in
{
  status = 200;
  stream = true; # Runs body derivation instead of building it
  sandbox = false; # Enables __noChroot
  path = false; # Body attribute refers to a store path which should be served

  headers = {
    "Content-type" = [ "application/json" ];
  }; # Value or derivation

  body = { }; # Value or derivation or
}
