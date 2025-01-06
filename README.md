
## Related

- https://blog.replit.com/nix_web_app
- https://discourse.nixos.org/t/bubblegum-a-nix-cgi-programming-framework/12259
- https://code.tvl.fyi/tree/web/bubblegum/README.md

Modes:
- Eval
- Build
- Run

## Usage

```shell
nix run github:stv0g/nix-web-api -- handler.nix
```

## Handler

```nix
{ method, uri, headers, body }: let
    pkgs = import <nixpkgs> { };
    web = import ./web-lib.nix pkgs;
 
    query = web.queryArgs uri;
in {
    status = 200;
    headers = { ... }; # Value or Derivation
    body = { ... }; # Value or Derivation or 

    stream = true;
    impure = false; # Enables __noChroot
}
```

## Use-cases
- Serve Nix store paths
- Serve single files or sub-directories from Nix stores
- Webhook Handlers
    - CI
        - GitHub webhooks
            - github-runner autoscaling