# Nixpresso Library Reference

This is the documentation for the Nixpresso library.

It is availble as a passthru from the main Nixpresso derivation. E.g:

```nix
let
  lib = import "${builtins.fetchTarball "https://github.com/stv0g/Nixpresso/archive/refs/heads/main.tar.gz"}/lib" { };
in
lib.handlers.htmlError { status = 404; details = "Not found"; }
```

Or as a Flake output:

```nix
let
  inherit (builtins.getFlake "github:stv0g:nixpresso") lib;
in
lib.handlers.htmlError { status = 404; details = "Not found"; }
```

## Contents

* HTTP Cookies: [`nixpresso.lib.cookie`](./cookie.md)
* Customisation: [`nixpresso.lib.customisation`](./customisation.md)
* Trivial Handlers: [`nixpresso.lib.handlers`](./handlers.md)
* HTML escaping: [`nixpresso.lib.html`](./html.md)
* Handlers support: [`nixpresso.lib.response`](./response.md)
* Trivial helpers: [`nixpresso.lib.trivial`](./trivial.md)
* URL parsing: [`nixpresso.lib.url`](./url.md)
