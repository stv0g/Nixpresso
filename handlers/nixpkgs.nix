{
  handlerFile,
  method,
  query,
  headers,
  path,
  ...
}@request:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;
  inherit (lib) removePrefix;
  inherit (builtins)
    split
    head
    readFileType
    trace
    ;

  npath = removePrefix "/nixpkgs/" path;
  parts = split "/" npath;

  attr = head parts;
  pkg = pkgs.${attr};

  subPath = removePrefix "/nixpkgs/${attr}/" path;

  file = "${pkg}/${subPath}";
  fileType = readFileType file;
in
trace { inherit fileType file; } (
  if fileType == "regular" then
    {
      status = 200;
      headers = {
        "Content-type" = [ "application/octet-stream" ];
      };
      body = file;
      path = true;
    }
  else if fileType == "directory" then
    if !lib.hasSuffix "/" path then
      {
        status = 301;
        headers = {
          Location = [ (path + "/") ];
        };
      }
    else
      let
        contents = builtins.readDir file;
        contentsList = lib.mapAttrsToList (name: type: name) contents;
        listItems = map (e: ''<li><a href="${e}">${e}</a></li>'') contentsList;
        list = "<ul>${lib.concatStrings listItems}</ul>";
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
              ${list}
            </body>
          </html>
        '';
      }
  else
    {
      status = 404;
      body = "not found. is ${fileType}";
    }
)
