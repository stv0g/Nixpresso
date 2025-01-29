# URL parsing {#sec-functions-library-url}


## `nixpresso.lib.url.decodeQueryString` {#function-library-nixpresso.lib.url.decodeQueryString}

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

## `nixpresso.lib.url.encodeQueryString` {#function-library-nixpresso.lib.url.encodeQueryString}

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

## `nixpresso.lib.url.escape` {#function-library-nixpresso.lib.url.escape}

Escape a URL string.

### Example

```nix
escape "foo bar"
=>
"foo%20bar"
```

### Type

```
escape :: String -> String
```

### Arguments

url
: A URL string

## `nixpresso.lib.url.full` {#function-library-nixpresso.lib.url.full}

Get the full URL of a request.

### Example

```nix
full {
  host = "example.com";
  uri = "/foo";
}
=>
"http://example.com/foo"
```

### Type

```
full :: { host: String, uri: String, ?tls: Boolean } -> String
```

### Arguments

request
: A request object

## `nixpresso.lib.url.unescape` {#function-library-nixpresso.lib.url.unescape}

Unescape a URL string.

### Example

```nix
unescape "foo%20bar"
=>
"foo bar"
```

### Type

```
unescape :: String -> String
```

### Arguments

url
: A URL string


