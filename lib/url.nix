# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (lib)
    attrNames
    concatStringsSep
    elemAt
    escapeURL
    fixedWidthString
    listToAttrs
    mapAttrsToList
    replaceStrings
    splitString
    toHexString
    ;

  asciiTable = import ./ascii-table.nix;

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
  decodeQueryString =
    qstr:
    listToAttrs (
      map (
        x:
        let
          parts = splitString "=" x;
        in
        {
          name = unescape' (elemAt parts 0);
          value = unescape' (elemAt parts 1);
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
  encodeQueryString =
    values: concatStringsSep "&" (mapAttrsToList (name: value: "${name}=${escape value}") values);

  /**
    Escape a URL string.

    # Example

    ```nix
    escape "foo bar"
    =>
    "foo%20bar"
    ```

    # Type

    ```
    escape :: String -> String
    ```

    # Arguments

    url
    : A URL string
  */
  escape = escapeURL;

  /**
    Unescape a URL string.

    # Example

    ```nix
    unescape "foo%20bar"
    =>
    "foo bar"
    ```

    # Type

    ```
    unescape :: String -> String
    ```

    # Arguments

    url
    : A URL string
  */
  unescape =
    let
      unreserved = [
        "A"
        "B"
        "C"
        "D"
        "E"
        "F"
        "G"
        "H"
        "I"
        "J"
        "K"
        "L"
        "M"
        "N"
        "O"
        "P"
        "Q"
        "R"
        "S"
        "T"
        "U"
        "V"
        "W"
        "X"
        "Y"
        "Z"
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
        "g"
        "h"
        "i"
        "j"
        "k"
        "l"
        "m"
        "n"
        "o"
        "p"
        "q"
        "r"
        "s"
        "t"
        "u"
        "v"
        "w"
        "x"
        "y"
        "z"
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "-"
        "_"
        "."
        "~"
      ];
      toUnescape = removeAttrs asciiTable unreserved;

      from = mapAttrsToList (_: c: "%${fixedWidthString 2 "0" (toHexString c)}") toUnescape;
      to = attrNames toUnescape;
    in
    replaceStrings from to;

  unescape' = url: unescape (replaceStrings [ "+" ] [ " " ] url);

  /**
    Get the full URL of a request.

    # Example

    ```nix
    full {
      host = "example.com";
      uri = "/foo";
    }
    =>
    "http://example.com/foo"
    ```

    # Type

    ```
    full :: { host: String, uri: String, ?tls: Boolean } -> String
    ```

    # Arguments

    request
    : A request object
  */
  full =
    request:
    let
      schema = if request ? tls && request.tls != null then "https" else "http";
    in
    "${schema}://${request.host}${request.uri}";
in
{
  inherit
    decodeQueryString
    encodeQueryString
    escape
    full
    unescape
    unescape'
    ;
}
