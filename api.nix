# Inspect handlers
{
  handlerFile,

  # Request data
  method ? "GET",
  uri ? "http://example.com/test",
  headers ? { },
  body ? null,
  ...
}@request:
let
  pkgs = import <nixpkgs> { };

  isDerivation = v: typeOf v == "set" && v ? type && v.type == "derivation";

  inherit (pkgs) lib;

  inherit (lib) assertMsg;

  inherit (builtins) typeOf functionArgs trace;

  handler = import handlerFile;
  args = functionArgs handler;
  type = typeOf handler;
  bodyRequired = args ? body;
in
assert assertMsg (typeOf handler == "lambda") "Handler must be a function";
{
  inspect = {
    inherit bodyRequired;
  };

  eval =
    let
      defaultResponse = {
        status = 200;
        body = "";
        path = false;
        stream = false;
      };
      actualResponse = handler request;
      response = defaultResponse // actualResponse;
    in
    # Check response
    assert assertMsg (typeOf response.status == "int") "Reponse attribute 'status' must be an integer";
    assert assertMsg (
      (response.path && isDerivation response.body) || (typeOf response.body == "string")
    ) "Response attribute 'body' must be a string";
    assert assertMsg (typeOf response.path == "bool") "Response attribute 'path' must be a boolean";
    assert assertMsg (typeOf response.stream == "bool") "Response attribute 'stream' must be a boolean";
    assert (!response.path || builtins.readFileType "${response.body}" != "dummy"); # Ugly hack: this forces a realization of the derivations output store-path
    response;
}
