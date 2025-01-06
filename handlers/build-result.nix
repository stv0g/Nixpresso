{
  handlerFile,
  method,
  uri,
  headers,
  ...
}@request:
let
  pkgs = import <nixpkgs> { };
in
{
  status = 200;
  headers = {
    "Content-type" = [ "application/octet-stream" ];
  };

  body = "${pkgs.hello}/bin/hello";
  bodyIsPath = true;

  stream = false; # Runs body derivation instead of building it
  sandbox = false; # Enables __noChroot
}
