# What is this
[RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986) is the standard for defining Uniform Resource Identifiers (a.k.a URIs, URLs)

This package is an implementation for [Odin](https://odin-lang.org/) as a port of the [Go](https://go.dev/) language [`net/url`](https://pkg.go.dev/net/url) package.

# Example
```odin
package example

import "core:fmt"
import "uri"

main :: proc() {
	identifier, ok := uri.parse("https://github.com/Creativty/odin_uri?w=1#example")
	assert(ok)

	fmt.println(identifier.scheme)   // "https"
	fmt.println(identifier.host)     // "github.com"
	fmt.println(identifier.path)     // "/Creativty/odin_uri"
	fmt.println(identifier.query)    // "w=1"
	fmt.println(identifier.fragment) // "example"
}
```
