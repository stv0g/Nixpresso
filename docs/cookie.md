# HTTP Cookies {#sec-functions-library-cookie}


## `nixpresso.lib.cookie.parse` {#function-library-nixpresso.lib.cookie.parse}

Parse a HTTP Cookie header into a Nix attribute set.

### Example

```nix
parse "foo=bar; baz=qux"
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

cookie
: A cookie header value


