# Localize Phone Number usage rules

Rules for LLM coding agents using `localize_phone_number` as a dependency. Not exhaustive — see the HexDocs guides for full reference.

## What this package is for

Parsing, validating and formatting international phone numbers, via Google's [libphonenumber](https://github.com/google/libphonenumber) C++ library through a NIF, with locale-aware defaults from [`localize`](https://hex.pm/packages/localize).

## Core conventions

* `Localize.PhoneNumber.parse/2` returns `{:ok, number}` or `{:error, exception}`. Everything else takes the parsed number, not the original string.

* Parsing needs a default territory for numbers written without a country code. It is derived from the locale when you do not pass one.

* `valid?/1` and `possible?/1` are different questions. *Possible* means the length and shape could be a number in that territory; *valid* means it matches a real assigned range. Use `valid?/1` before storing, `possible?/1` for optimistic input feedback.

## Module map

| Task | Use |
|---|---|
| Parse a number string | `Localize.PhoneNumber.parse/2` |
| Validate | `Localize.PhoneNumber.valid?/1`, `valid_for_territory?/2` |
| Cheap shape check | `Localize.PhoneNumber.possible?/1` |
| Format (E.164, international, national) | `Localize.PhoneNumber.to_string/2` |
| Line type (mobile, fixed line, VoIP) | `Localize.PhoneNumber.type/1` |
| Territory a number belongs to | `Localize.PhoneNumber.territory/1` |

## Things not to do

* **Do not validate phone numbers with a regular expression.** Numbering plans change, lengths vary by territory and by line type, and no regex tracks them. This package exists because that approach does not work.

* Do not store a number as the user typed it. Parse and store the E.164 form, and format for display at render time.

* Do not assume a number's territory from the user's locale or IP. Parse it and ask with `territory/1`.

* Do not assume a leading `+` is present, or that a number without one is national. Pass the default territory explicitly when you know it.

* Do not treat `possible?/1` as validation. It is deliberately permissive.
