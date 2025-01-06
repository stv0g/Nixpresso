{
  handlerFile,
  method,
  uri,
  headers,
  ...
}@request:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;
in
{
  status = 200;
  headers = {
    "Content-type" = [ "text/html" ];
  };

  body = ''
    <html lang="en">
      <title>nix-web-api Example</title>
      <body>
        <div class="">
          <h2>Request details</h2>
          <pre>${lib.generators.toPretty { } request}</pre>
        </div>
      </body>
    </html>
  '';

  stream = false; # Runs body derivation instead of building it
  sandbox = false; # Enables __noChroot
}
