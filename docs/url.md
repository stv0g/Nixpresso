# URL parsing {#sec-functions-library-url}


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


