{ path, body, ... }@request:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;
  inherit (lib) removePrefix;
  inherit (builtins)
    pathExists
    toString
    split
    head
    ;

  npath = removePrefix "/" path;
  parts = split "/" npath;
  route = head parts;
  handlerFile = ./. + "/${route}.nix";
in
if pathExists handlerFile then
  import handlerFile request
else
  {
    status = 404;
    body = "Handler not found: ${toString handlerFile}";
  }
