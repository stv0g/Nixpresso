# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  url,
}:
let
  inherit (lib)
    listToAttrs
    splitString
    concatStringsSep
    mapAttrsToList
    elemAt
    ;

  /**
    Parse a query string into a Nix attribute set.

    # Example

    ```nix
    parse "foo=bar&baz=qux"
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

    qstr
    : A query string
  */
  decode =
    qstr:
    listToAttrs (
      map (
        x:
        let
          parts = splitString "=" x;
        in
        {
          name = url.unescape' (elemAt parts 0);
          value = url.unescape' (elemAt parts 1);
        }
      ) (splitString "&" qstr)
    );

  /**
    Serialize a Nix attribute set into a query string.

    # Example

    ```nix
    encode { foo = "bar"; baz = "qux"; }
    =>
    "foo=bar&baz=qux"
    ```

    # Type

    ```
    encode :: AttrSet -> String
    ```

    # Arguments

    values
    : A Nix attribute set
  */
  encode =
    values: concatStringsSep "&" (mapAttrsToList (name: value: "${name}=${url.escape value}") values);
in
{
  inherit decode encode;
}
