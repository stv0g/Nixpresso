# HTTP query strings {#sec-functions-library-query}


## `nixpresso.lib.query.decode` {#function-library-nixpresso.lib.query.decode}

Parse a query string into a Nix attribute set.

### Example

```nix
parse "foo=bar&baz=qux"
=>
{
  foo = "bar";
  baz = "qux";
}
```

### Type

```
parse :: String -> AttrSet
```

### Arguments

qstr
: A query string

## `nixpresso.lib.query.encode` {#function-library-nixpresso.lib.query.encode}

Serialize a Nix attribute set into a query string.

### Example

```nix
encode { foo = "bar"; baz = "qux"; }
=>
"foo=bar&baz=qux"
```

### Type

```
encode :: AttrSet -> String
```

### Arguments

values
: A Nix attribute set


