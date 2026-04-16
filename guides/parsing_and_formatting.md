# Parsing and Formatting Guide

This guide explains how to use `Localize.PhoneNumber` for parsing, formatting, and validating phone numbers.

## Parsing

`Localize.PhoneNumber.parse/2` is the entry point for all phone number operations. It accepts a string and returns a `Localize.PhoneNumber.Number` struct that can be passed to all other functions.

### International format

Numbers that begin with `+` and a country code are parsed without any additional context:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> phone_number.country_code
1
iex> phone_number.national_number
6502530000
```

### National format with a territory

National-format numbers need a default territory so the parser knows which country's dialling plan to apply. Pass the `:territory` option with an ISO 3166-1 alpha-2 code:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", territory: "GB")
iex> phone_number.country_code
44

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("(650) 253-0000", territory: :US)
iex> phone_number.country_code
1
```

Territory values are validated via `Localize.validate_territory/1`, so both strings and atoms are accepted.

### National format with a locale

Instead of an explicit territory you can supply a `:locale` option. The territory is extracted from the locale via `Localize.Territory.territory_from_locale/1`:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", locale: "en-GB")
iex> phone_number.country_code
44

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", locale: :en_GB)
iex> phone_number.country_code
44
```

The locale can also be a `Localize.LanguageTag.t()` struct returned by `Localize.get_locale/0` or `Localize.validate_locale/1`.

### Default territory from the process locale

When neither `:territory` nor `:locale` is given, the default territory is derived from the current process locale set by `Localize.put_locale/1`:

```elixir
iex> Localize.put_locale("en-AU")
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("02 1234 5678")
iex> phone_number.country_code
61
```

### Extensions

Phone number extensions are preserved during parsing:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000 ext. 123")
iex> phone_number.extension
"123"
```

When no extension is present the field is `nil`.

### Parse errors

If the input cannot be parsed, an error tuple is returned with a reason string:

```elixir
iex> Localize.PhoneNumber.parse("not a number")
{:error, "not_a_number"}

iex> Localize.PhoneNumber.parse("1", territory: "US")
{:error, "not_a_number"}
```

## Formatting

`Localize.PhoneNumber.to_string/2` formats a parsed phone number as a string. Four format types are supported:

### International (default)

Includes the country code prefix with spaces between groups:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.to_string(phone_number)
{:ok, "+1 650-253-0000"}

iex> Localize.PhoneNumber.to_string(phone_number, :international)
{:ok, "+1 650-253-0000"}
```

### E.164

The canonical machine-readable format with no spaces or punctuation:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.to_string(phone_number, :e164)
{:ok, "+16502530000"}
```

### National

The format used within the number's home country, without the country code:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "(650) 253-0000"}
```

### RFC 3966

The `tel:` URI format used in SIP and web links:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.to_string(phone_number, :rfc3966)
{:ok, "tel:+1-650-253-0000"}
```

## Validation

Three levels of validation are available:

### Full validation

`valid?/1` checks that the number has the correct length and matches a known pattern for its territory and type:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.valid?(phone_number)
true
```

### Territory-specific validation

`valid_for_territory?/2` checks that the number is valid and belongs to the given territory:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.valid_for_territory?(phone_number, "US")
true

iex> Localize.PhoneNumber.valid_for_territory?(phone_number, "GB")
false
```

### Possibility check

`possible?/1` is a lighter check that only verifies the number has a plausible length. It runs faster but may accept numbers that `valid?/1` would reject:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.possible?(phone_number)
true
```

## Type Detection

`type/1` classifies a phone number by its type. The return value is one of the following atoms:

| Atom | Description |
|------|-------------|
| `:fixed_line` | Landline number. |
| `:mobile` | Mobile/cellular number. |
| `:fixed_line_or_mobile` | Could be either (common in US/Canada). |
| `:toll_free` | Freephone number. |
| `:premium_rate` | Premium-rate service number. |
| `:shared_cost` | Shared-cost number. |
| `:voip` | Voice over IP number. |
| `:personal_number` | Personal routing number. |
| `:pager` | Paging service number. |
| `:uan` | Universal access number (company routing). |
| `:voicemail` | Voicemail access number. |
| `:unknown` | Type could not be determined. |

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 800-555-0199")
iex> Localize.PhoneNumber.type(phone_number)
:toll_free

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.type(phone_number)
:fixed_line_or_mobile
```

## Territory Lookup

`territory/1` returns the ISO 3166-1 alpha-2 territory code for a parsed number, or `nil` if the territory cannot be determined:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.territory(phone_number)
"US"

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+44 20 7946 0958")
iex> Localize.PhoneNumber.territory(phone_number)
"GB"

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+61 2 1234 5678")
iex> Localize.PhoneNumber.territory(phone_number)
"AU"
```

International service numbers (such as `+800`) return `"001"` — the non-geographic territory code used by libphonenumber.
