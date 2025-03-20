package uri

import "core:log"
import "core:strings"

Encoding_Mode :: enum {
	Path = 1,
	Path_Segment,
	Host,
	Zone,
	Userinfo,
	Query_Component,
	Fragment,
}

@(private="file")
hex_to_int :: proc(c: byte) -> int {
	switch {
	case '0' <= c && c <= '9':
		return int(c - '0')
	case 'a' <= c && c <= 'f':
		return int(c - 'a') + 10
	case 'A' <= c && c <= 'F':
		return int(c - 'A') + 10
	}
	return 0
}

should_encode :: proc(c: rune, mode: Encoding_Mode) -> bool {
	if is_alpha(c) || is_digit(c) do return false
	if mode == .Host || mode == .Zone {
		if strings.contains_rune("!$&\'()*+,;=:[]<>\"", c) {
			return false
		}
	}
	switch c {
	case '-', '_', '.', '~':
		return false
	case '$', '&', '+', ',', '/', ':', ';', '=', '?', '@':
		if mode == .Fragment do return false
		if mode == .Path do return c == '?'
		if mode == .Path_Segment do return c == '/' || c == ';' || c == ',' || c == '?'
		if mode == .Userinfo do return c == '@' || c == '/' || c == '?' || c == ':'
		if mode == .Query_Component do return true
	}

	if mode == .Fragment {
		switch c {
		case '!', '(', ')', '*':
			return false
		}
	}
	return true
}

decode :: proc(text: string, mode: Encoding_Mode) -> (decoded: string, ok: bool) {
	r := reader_make(text)
	has_plus := false
	encoded_count := 0
	for !reader_eof(&r) {
		c := reader_next(&r)
		switch c {
		case '+':
			has_plus = (mode == .Query_Component)
		case '%':
			a, b := cast(byte)reader_next(&r), cast(byte)reader_next(&r)
			if !is_hex(cast(rune)a) || !is_hex(cast(rune)b) do return "", false
			if mode == .Host && hex_to_int(a) < 8 && !(a == '2' && b == '5') do return "", false
			if mode == .Zone {
				value := (hex_to_int(a) << 4) | hex_to_int(b)
				if value != ' ' && !(a == '2' && b == '5') && should_encode(cast(rune)value, .Host) {
					log.warnf("issue")
					return "::64", false
				}
			}
			encoded_count += 1
		case:
			if (mode == .Host || mode == .Zone) && c < 0x80 && should_encode(c, mode) {
				log.warnf("default")
				return "", false
			}
		}
	}

	if encoded_count == 0 && !has_plus do return strings.clone(text), true

	b: strings.Builder
	strings.builder_init(&b)
	defer strings.builder_destroy(&b)

	for i := 0; i < len(text); i += 1 {
		switch text[i] {
		case '%':
			c_decoded := cast(byte)((hex_to_int(text[i+1]) * 16) | hex_to_int(text[i + 2]))
			strings.write_byte(&b, c_decoded)
			i += 2
		case '+':
			if mode == .Query_Component do strings.write_byte(&b, ' ')
			else do strings.write_byte(&b, '+')
		case:
			strings.write_byte(&b, text[i])
		}
	}

	decoded = strings.clone(strings.to_string(b))
	return decoded, true
}

encode :: proc(text: string, mode: Encoding_Mode) -> (encoded: string) {
	space_count, hex_count: int
	for c in text {
		if should_encode(c, mode) {
			if mode == .Query_Component && c == ' ' do space_count += 1
			else do hex_count += 1
		}
	}

	if space_count == 0 && hex_count == 0 do return strings.clone(text)

	b: strings.Builder
	strings.builder_init(&b)
	defer strings.builder_destroy(&b)

	for c in text {
		switch {
		case mode == .Query_Component && c == ' ':
			strings.write_byte(&b, '+')
		case should_encode(c, mode):
			strings.write_byte(&b, '%')
			strings.write_byte(&b, byte(c >>  4))
			strings.write_byte(&b, byte(c  & 15))
		case:
			strings.write_byte(&b, byte(c))
		}
	}

	encoded = strings.clone(strings.to_string(b))
	return encoded
}
