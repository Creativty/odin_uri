package uri

import "core:strings"

@(private)
CHARSET_RESERVED :: ":/?#[]@!$&'()*+,;="

@(private)
CHARSET_ALPHA :: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

@(private)
CHARSET_DIGIT :: "0123456789"

@(private)
CHARSET_HEX :: CHARSET_DIGIT + "abcdefABCDEF"

is_reserved :: proc(c: rune) -> bool {
	return strings.contains_rune(CHARSET_RESERVED, c)
}

is_alpha :: proc(c: rune) -> bool {
	return strings.contains_rune(CHARSET_ALPHA, c)
}

is_digit :: proc(c: rune) -> bool {
	return strings.contains_rune(CHARSET_DIGIT, c)
}

is_hex :: proc(c: rune) -> bool {
	return strings.contains_rune(CHARSET_HEX, c)
}

is_scheme_suffix :: proc(c: rune) -> bool {
	is_special :: proc(c: rune) -> bool {
		CHARSET_SPECIAL :: "+-."
		return strings.contains_rune(CHARSET_SPECIAL[:], c)
	}
	return is_alpha(c) || is_digit(c) || is_special(c)
}
