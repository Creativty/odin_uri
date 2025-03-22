package uri

import "core:log"
import "core:strings"

// RFC3986		Uniform Resource Identifier (URI): Generic Syntax
// Reference:	  https://datatracker.ietf.org/doc/html/rfc3986

// TLDs :: #load("tlds.txt", string)

URI :: struct {
	scheme: string,

	userinfo: string,
	host: string,
	port: string,
	path: string,
	opaque: string,

	query: string,
	fragment: string,
}

@(private)
_check_userinfo :: proc(text: string) -> (valid: bool) {
	for c in text {
		switch c {
		case '0'..='9':
		case 'A'..='Z', 'a'..='z':
		case '-', '.', '_', ':', '~', '!', '$', '&', '\'', '(', ')', '*', '+', ',', ';', '=', '%', '@':
		case:
			return false
		}
	}
	return true
}

@(private)
_check_colon_port :: proc(text: string) -> (valid: bool) {
	if text == "" do return true
	if text[0] != ':' do return false
	for c in text[1:] {
		switch c {
		case '0'..='9':
			continue
		case:
			return false
		}
	}
	return true
}

@(private)
_parse_scheme :: proc(uri: ^URI, text: string) -> (rest: string, ok: bool) {
	for c, i in text {
		switch c {
		case 'a'..='z', 'A'..='Z':
			continue
		case '0'..='9', '+', '-', '.':
			if i == 0 do return text, true
		case ':':
			if i == 0 do return "", false
			scheme := strings.clone(text[:i])
			defer delete(scheme)

			uri.scheme = strings.to_lower(scheme)
			return text[i+1:], true
		case:
			return text, true
		}
	}
	return text, true
}

@(private)
_parse_host :: proc(uri: ^URI, text: string) -> (ok: bool) {
	text := text

	if strings.has_prefix(text, "[") { // IPv6
		index_bracket := strings.last_index(text, "]")
		if index_bracket < 0 do return false

		colon_port := text[index_bracket+1:]
		_check_colon_port(colon_port) or_return

		index_zone := strings.index(text[:index_bracket], "%25")
		if index_zone >= 0 {
			ipv6 := decode(text[:index_zone], .Host) or_return
			defer delete(ipv6)

			zone := decode(text[index_zone:index_bracket+1], .Zone) or_return
			defer delete(zone)

			uri.host = strings.concatenate({ ipv6, zone })
			uri.port = strings.clone(colon_port[1 if len(colon_port) > 0 else 0:])
			return true
		} else {
			uri.host = decode(text[:index_bracket+1], .Host) or_return
			uri.port = strings.clone(colon_port[1 if len(colon_port) > 0 else 0:])
			return true
		}
	}
	if index_port := strings.last_index(text, ":"); index_port >= 0 {
		colon_port := text[index_port:]
		_check_colon_port(colon_port) or_return
		uri.port = strings.clone(colon_port[1:])
		uri.host, ok = decode(text[:index_port], .Host)
	} else do uri.host, ok = decode(text, .Host)
	return ok
}

@(private)
_parse_authority :: proc(uri: ^URI, text: string) -> (ok: bool) {
	i := strings.last_index(text, "@")
	_parse_host(uri, text if i < 0 else text[i+1:]) or_return
	if i < 0 do return true

	userinfo := text[:i]
	if !_check_userinfo(userinfo) do return false
	uri.userinfo, ok = decode(userinfo, .Userinfo)
	return ok
}

@(private)
_parse :: proc(text: string, via_request := false) -> (uri: URI, ok: bool) {
	// TODO(XENOBAS): Handle control bytes

	if text == "" && via_request do return uri, false
	if text == "*" {
		uri.path = strings.clone(text)
		return uri, true
	}

	rest := _parse_scheme(&uri, text) or_return

	if strings.has_suffix(rest, "?") && strings.count(rest, "?") == 1 do rest = rest[:len(rest) - 1]
	else {
		rest, _, uri.query = strings.partition(rest, "?")
		uri.query = strings.clone(uri.query)
	}

	if !strings.has_prefix(rest, "/") {
		if uri.scheme != "" {
			uri.opaque = strings.clone(rest)
			return uri, true
		}
		if via_request do return uri, false
		if segment, _, _ := strings.partition(rest, "/"); strings.contains_rune(segment, ':') do return uri, false
	}

	if (uri.scheme != "" || (!via_request && !strings.has_prefix(rest, "///"))) && strings.has_prefix(rest, "//") {
		authority: string
		authority, rest = rest[2:], ""
		if i := strings.index(authority, "/"); i >= 0 do authority, rest = authority[:i], authority[i:]
		_parse_authority(&uri, authority) or_return
	} else if uri.scheme != "" && strings.has_prefix(rest, "/") {
		// OmitHost ?!?
	}

	uri.path = decode(rest, .Path) or_return
	return uri, true
}

parse :: proc(text: string) -> (uri: URI, ok: bool) {
	text, _, frag := strings.partition(text, "#")

	uri, ok = _parse(text)
	if !ok do return uri, false
	if frag == "" do return uri, true

	uri.fragment = decode(frag, .Fragment) or_return
	return uri, true
}

parse_reference :: proc(base: URI, text: string) -> (uri: URI, ok: bool) {
	ref := parse(text) or_return
	defer destroy(ref)

	uri = resolve_reference(base, ref)
	return
}

resolve_reference :: proc(base: URI, ref: URI) -> (uri: URI) {
	uri = clone(base)
	if ref.scheme == "" {
		delete(uri.scheme)

		uri.scheme = strings.clone(base.scheme)
	}

	if ref.scheme != "" || ref.host != "" || ref.userinfo != "" {
		delete(uri.path)

		uri.path = resolve_path(ref.path, "")
		return uri
	}

	if ref.opaque != "" {
		delete(uri.host)
		delete(uri.path)
		delete(uri.userinfo)

		uri.host     = strings.clone("")
		uri.port     = strings.clone("")
		uri.userinfo = strings.clone("")
	}

	if ref.path == "" && ref.query == "" {
		delete(uri.query)

		uri.query = strings.clone("")
		if ref.fragment == "" {
			delete(uri.fragment)

			uri.fragment = strings.clone(base.fragment)
		}
	}

	delete(uri.path)
	delete(uri.host)
	delete(uri.userinfo)

	uri.path = resolve_path(base.path, ref.path)
	uri.host = strings.clone(base.host)
	uri.userinfo = strings.clone(base.userinfo)
	return uri
}

resolve_path :: proc(base: string, ref: string) -> (path: string) {
	full: string

	if ref == "" {
		full = strings.clone(base)
	} else if !strings.has_prefix(ref, "/") {
		index_slash := strings.last_index(base, "/")
		full = strings.join({ base[:index_slash+1], ref }, "")
	} else {
		full = strings.clone(ref)
	}
	if full == "" do return full
	defer delete(full)

	dest: strings.Builder
	left: string
	slash: string

	strings.builder_init(&dest)
	strings.write_byte(&dest, '/')
	defer strings.builder_destroy(&dest)

	first := true
	right := full
	contains_slash := true
	for contains_slash {
		left, slash, right = strings.partition(right, "/")
		contains_slash = (slash == "/")
		switch left {
		case ".":
			first = false
			continue
		case "..":
			str := strings.to_string(dest)[1:]
			index := strings.last_index_byte(str, '/')

			strings.builder_reset(&dest)
			strings.write_byte(&dest, '/')

			if index >= 0 do strings.write_string(&dest, str[:index])
			else do first = true
		case:
			if !first do strings.write_byte(&dest, '/')
			first = false

			strings.write_string(&dest, left)
		}
	}
	if left == "." || left == ".." do strings.write_byte(&dest, '/')

	path = strings.to_string(dest)
	if len(path) > 1 && path[1] == '/' do path = path[1:]
	return strings.clone(path)
}

clone :: proc(src: URI) -> (dst: URI) {
	dst.scheme = strings.clone(src.scheme)

	dst.userinfo = strings.clone(src.userinfo)
	dst.host = strings.clone(src.host)
	dst.port = strings.clone(src.port)
	dst.path = strings.clone(src.path)
	dst.opaque = strings.clone(src.opaque)

	dst.query = strings.clone(src.query)
	dst.fragment = strings.clone(src.fragment)

	return
}

destroy :: proc(uri: URI) {
	delete(uri.fragment)
	delete(uri.host)
	delete(uri.opaque)
	delete(uri.path)
	delete(uri.port)
	delete(uri.query)
	delete(uri.scheme)
	delete(uri.userinfo)
}
