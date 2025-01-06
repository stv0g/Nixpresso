# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (lib)
    head
    tail
    listToAttrs
    map
    splitString
    trim
    ;
in
{
  /**
    Parse a HTTP Cookie header into a Nix attribute set.

    # Example

    ```nix
    parse "foo=bar; baz=qux"
    =>
    {
      foo = "bar";
      baz = "qux";
    }
    ```

    # Type

    ```
    parse :: String -> AttrSet
    ```

    # Arguments

    cookie
    : A cookie header value
  */
  parse =
    headers:
    let
      cookieHeader = head headers.Cookie;
      cookieKVs = splitString ";" cookieHeader;
    in
    if headers ? Cookie then
      listToAttrs (
        map (
          kv:
          let
            kvParts = lib.splitString "=" kv;
          in
          {
            name = trim (head kvParts);
            value = trim (head (tail kvParts));
          }
        ) cookieKVs
      )
    else
      { };
}
