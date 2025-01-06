{
  handlerFile,
  method,
  uri,
  headers,
  ...
}@request:
{
  status = 200;
  headers = {
    "Content-type" = [ "application/json" ];
  };

  body = builtins.toJSON { some = "value"; };

  stream = false; # Runs body derivation instead of building it
  sandbox = false; # Enables __noChroot
}
