package uri

import "core:log"
import "core:testing"

URI_Expect :: struct {
	text: string,
	ok: bool,
	uri: URI,
}

url_tests := [?]URI_Expect{
	{ "", true, { } },
	{ "tel:+1-816-555-1212", true, { scheme = "tel", opaque = "+1-816-555-1212" } },
	{ "https://youtube.com:443/watch?v=3b3f9087a", true, { scheme = "https", host = "youtube.com", port = "443", path = "/watch", query = "v=3b3f9087a" }, },
	{ "telnet://192.0.2.16:80?add=true", true, { scheme = "telnet", host = "192.0.2.16", port = "80", query = "add=true" } },
	{ "news:comp.infosystems.www.servers.unix", true, { scheme = "news", opaque = "comp.infosystems.www.servers.unix" } },
	{ "http://username:password@localhost:8080/about#contact", true, { scheme = "http", userinfo = "username:password", host = "localhost", port = "8080", path = "/about", fragment = "contact" } },
	{ "mongodb+srv://myDatabaseUser:D1fficultPassw0rd@server.example.com/?connectionsLimit=3", true, { scheme = "mongodb+srv", userinfo = "myDatabaseUser:D1fficultPassw0rd", host = "server.example.com", path = "/", query = "connectionsLimit=3" } },
	{ "file:///etc/hosts.conf", true, { scheme = "file", path = "/etc/hosts.conf" } },
	{ "/index.html", true, { path = "/index.html" } },
	{ "./channels/788078738905628682/1174105404695916686", true, { path = "./channels/788078738905628682/1174105404695916686" } },
	{ "http://[fe80::1%25en0]/", true, { scheme = "http", host = "[fe80::1%en0]", path = "/" } },
	{ "gemini://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]:1965/docs/faq.gmi", true, { scheme = "gemini", host = "[2001:0db8:85a3:0000:0000:8a2e:0370:7334]", port = "1965", path = "/docs/faq.gmi" } },

	// go lang test suite
	{ "http://google.com", true, { scheme = "http", host = "google.com" } },
	{ "http://google.com/", true, { scheme = "http", host = "google.com", path = "/" } },
	{ "http://www.google.com/file%20one%26two", true, { scheme = "http", host = "www.google.com", path = "/file one&two" } },
	{ "http://www.google.com/#file%20one%26two", true, { scheme = "http", host = "www.google.com", path = "/", fragment = "file one&two" } },
	{ "ftp://webmaster@www.google.com/", true, { scheme = "ftp", userinfo = "webmaster", host = "www.google.com", path = "/" } },
	{ "ftp://john%20doe@www.google.com/", true, { scheme = "ftp", userinfo = "john doe", host = "www.google.com", path = "/" } },
	{ "http://www.google.com/?", true, { scheme = "http", host = "www.google.com", path = "/" } },
	{ "http://www.google.com/?foo=bar?", true, { scheme = "http", host = "www.google.com", path = "/", query = "foo=bar?" } },
	{ "http://www.google.com/?q=odin+language", true, { scheme = "http", host = "www.google.com", path = "/", query = "q=odin+language" } },
	{ "http://www.google.com/?q=odin%20language", true, { scheme = "http", host = "www.google.com", path = "/", query = "q=odin%20language" } },
	{ "http://www.google.com/a%20b?q=c+d", true, { scheme = "http", host = "www.google.com", path = "/a b", query = "q=c+d" } },
	{ "http:www.google.com/?q=odin+language", true, { scheme = "http", opaque = "www.google.com/", query = "q=odin+language" } },
	{ "http:%2f%2fwww.google.com/?q=odin+language", true, { scheme = "http", opaque = "%2f%2fwww.google.com/", query = "q=odin+language" } },
	{ "mailto:/webmaster@odinlang.org", true, { scheme = "mailto", path = "/webmaster@odinlang.org" } },
	{ "mailto:webmaster@odinlang.org", true, { scheme = "mailto", opaque = "webmaster@odinlang.org" } },
	{ "/foo?query=http://bad", true, { path = "/foo", query = "query=http://bad" } },
	{ "//foo", true, { host = "foo" } },
	{ "//user@foo/path?a=b", true, { host = "foo", userinfo = "user", path = "/path", query = "a=b" } },
	{ "///threeslashes", true, { path = "///threeslashes" } },
	{ "http://user:password@google.com", true, { scheme = "http", userinfo = "user:password", host = "google.com" } },
	{ "http://j@ne:password@google.com", true, { scheme = "http", userinfo = "j@ne:password", host = "google.com" } },
	{ "http://jane:p@ssword@google.com", true, { scheme = "http", userinfo = "jane:p@ssword", host = "google.com" } },
	{ "http://j%40ne:password@google.com/p@th?lang=@din", true, { scheme = "http", userinfo = "j@ne:password", host = "google.com", path = "/p@th", query = "lang=@din" } },
	{ "http://www.google.com/?q=odin+language#hugin", true, { scheme = "http", host = "www.google.com", path = "/", query = "q=odin+language", fragment = "hugin" } },
	{ "http://www.google.com/?q=odin+language#hugin&munin", true, { scheme = "http", host = "www.google.com", path = "/", query = "q=odin+language", fragment = "hugin&munin" } },
	{ "http://www.google.com/?q=odin+language#hugin%26munin", true, { scheme = "http", host = "www.google.com", path = "/", query = "q=odin+language", fragment = "hugin&munin" } },
	{ "file:///home/adg/rabbits", true, { scheme = "file", path = "/home/adg/rabbits" } },
	{ "file:///C:/System%2032/ld.exe", true, { scheme = "file", path = "/C:/System 32/ld.exe" } },
	{ "MaIlTo:webmaster@odinlang.org", true, { scheme = "mailto", opaque = "webmaster@odinlang.org" } },
	{ "a/b/c", true, { path = "a/b/c" } },
	{ "http://%3Fam:pa%3Fsword@google.com", true, { scheme = "http", userinfo = "?am:pa?sword", host = "google.com" } },
	{ "http://192.168.0.1/", true, { scheme = "http", host = "192.168.0.1", path = "/" } },
	{ "http://192.168.0.1:8000/", true, { scheme = "http", host = "192.168.0.1", port = "8000", path = "/" } },
	{ "http://[fe80::1]/", true, { scheme = "http", host = "[fe80::1]", path = "/" } },
	{ "http://[fe80::1]:8080/", true, { scheme = "http", host = "[fe80::1]", port = "8080", path = "/" } },
	{ "http://[fe80::1%25eno0]/", true, { scheme = "http", host = "[fe80::1%eno0]", path = "/" } },
	{ "http://[fe80::1%25eno0]:8000/", true, { scheme = "http", host = "[fe80::1%eno0]", port = "8000", path = "/" } },
	{ "http://[fe80::1%25eno0]:8000/", true, { scheme = "http", host = "[fe80::1%eno0]", port = "8000", path = "/" } },
	{ "http://[fe80::1%25%65%6e%301]/", true, { scheme = "http", host = "[fe80::1%en01]", path = "/" } },
	{ "http://[fe80::1%25%65%6e%301-._~]/", true, { scheme = "http", host = "[fe80::1%en01-._~]", path = "/" } },
	{ "http://[fe80::1%25%65%6e%301-._~]:8080/", true, { scheme = "http", host = "[fe80::1%en01-._~]", path = "/", port = "8080" } },
	{ "http://rest.rsc.io/foo%2fbar/baz%2Fquux?alt=media", true, { scheme = "http", host = "rest.rsc.io", path = "/foo/bar/baz/quux", query = "alt=media" } },
	{ "mysql://a,b,c/bar", true, { scheme = "mysql", host = "a,b,c", path = "/bar" } },
	{ "scheme://!$&'()*+,;=hello!:1/path", true, { scheme = "scheme", host = "!$&'()*+,;=hello!", port = "1", path = "/path" } },
	{ "http://host/!$&'()*+,;=:@[hello]", true, { scheme = "http", host = "host", path = "/!$&'()*+,;=:@[hello]" } },
	{ "http://example.com/oid/[order_id]", true, { scheme = "http", host = "example.com", path = "/oid/[order_id]" } },
	{ "http://192.168.0.2:8080/foo", true, { scheme = "http", host = "192.168.0.2", path = "/foo", port = "8080" } },
	{ "http://192.168.0.2:/foo", true, { scheme = "http", host = "192.168.0.2", path = "/foo" } },
	{ "http://2b01:e34:ef40:7730:8e70:5aff:fefe:edac:8080/foo", true, { scheme = "http", host = "2b01:e34:ef40:7730:8e70:5aff:fefe:edac", port = "8080", path = "/foo" } },
	{ "http://2b01:e34:ef40:7730:8e70:5aff:fefe:edac:/foo", true, { scheme = "http", host = "2b01:e34:ef40:7730:8e70:5aff:fefe:edac", path = "/foo" } },
	{ "http://[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]:8080/foo", true, { scheme = "http", host = "[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]", port = "8080", path = "/foo" } },
	{ "http://[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]/foo", true, { scheme = "http", host = "[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]", path = "/foo" } },
	{ "http://hello.世界.com/foo", true, { scheme = "http", host = "hello.世界.com", path = "/foo" } },
	{ "http://hello.%e4%b8%96%e7%95%8c.com/foo", true, { scheme = "http", host = "hello.世界.com", path = "/foo" } },
	{ "http://hello.%E4%B8%96%E7%95%8C.com/foo", true, { scheme = "http", host = "hello.世界.com", path = "/foo" } },
	{ "http://example.com//foo", true, { scheme = "http", host = "example.com", path = "//foo" } },
	{ "myscheme://authority<\"hellope\">/foo", true, { scheme = "myscheme", host = "authority<\"hellope\">", path = "/foo" } },
	{ "tcp://[2020::2020:20:2020:2020%25Windows%20Loves%20Spaces]:2020", true, { scheme = "tcp", host = "[2020::2020:20:2020:2020%Windows Loves Spaces]", port = "2020" } },
	{ "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a&dn", true, { scheme= "magnet", query = "xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a&dn" } },
	{ "mailto:?subject=hellope", true, { scheme= "mailto", query = "subject=hellope" } },
}

@(test)
test_parse_list :: proc(t: ^testing.T) {
	for reference in url_tests {
		uri, ok := parse(reference.text)
		defer destroy(uri)

		testing.expect_value(t, ok, reference.ok)
		testing.expect_value(t, uri.scheme, reference.uri.scheme)
		testing.expect_value(t, uri.userinfo, reference.uri.userinfo)
		testing.expect_value(t, uri.host, reference.uri.host)
		testing.expect_value(t, uri.port, reference.uri.port)
		testing.expect_value(t, uri.path, reference.uri.path)
		testing.expect_value(t, uri.opaque, reference.uri.opaque)
		testing.expect_value(t, uri.query, reference.uri.query)
		testing.expect_value(t, uri.fragment, reference.uri.fragment)
	}
}
