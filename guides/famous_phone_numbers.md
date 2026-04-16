# Famous Phone Numbers Guide

A tour of `Localize.PhoneNumber` through phone numbers from movies, television, and music. Each example demonstrates parsing, formatting, validation, and type detection on a recognizable number.

## Ghostbusters — "Who you gonna call?"

The Ghostbusters ad told New York to dial 555-2368. With a full area code the number parses and formats correctly:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 212-555-2368")
iex> Localize.PhoneNumber.to_string(phone_number, :e164)
{:ok, "+12125552368"}

iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "(212) 555-2368"}

iex> Localize.PhoneNumber.territory(phone_number)
"US"

iex> Localize.PhoneNumber.valid?(phone_number)
true
```

Without an area code the seven-digit local number still parses, but libphonenumber cannot validate it:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("555-2368", territory: "US")
iex> Localize.PhoneNumber.valid?(phone_number)
false
```

## Jenny — 867-5309

Tommy Tutone's 1981 hit gave us the most dialled number in pop music. As a seven-digit local number it parses but is not valid without an area code:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("867-5309", territory: "US")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "867-5309"}

iex> Localize.PhoneNumber.valid?(phone_number)
false
```

Give Jenny a proper area code and the number becomes fully valid:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 415-867-5309")
iex> Localize.PhoneNumber.to_string(phone_number, :international)
{:ok, "+1 415-867-5309"}

iex> Localize.PhoneNumber.valid?(phone_number)
true

iex> Localize.PhoneNumber.type(phone_number)
:fixed_line_or_mobile
```

## The Shining — Overlook Hotel, Colorado

Stanley Kubrick's Overlook Hotel sits in Colorado (area code 303). Using the 555 range reserved for fiction:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("(303) 555-0147", territory: "US")
iex> Localize.PhoneNumber.to_string(phone_number, :e164)
{:ok, "+13035550147"}

iex> Localize.PhoneNumber.to_string(phone_number, :international)
{:ok, "+1 303-555-0147"}

iex> Localize.PhoneNumber.territory(phone_number)
"US"
```

## International numbers from film

### Tokyo — Lost in Translation

The Park Hyatt Tokyo and its surroundings use a Shinjuku-area number:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+81 3-1234-5678")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "03-1234-5678"}

iex> Localize.PhoneNumber.territory(phone_number)
"JP"

iex> Localize.PhoneNumber.type(phone_number)
:fixed_line
```

### Paris — Amélie

A Parisian landline in the 1st arrondissement:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+33 1 42 68 53 00")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "01 42 68 53 00"}

iex> Localize.PhoneNumber.territory(phone_number)
"FR"

iex> Localize.PhoneNumber.type(phone_number)
:fixed_line
```

### London — Sherlock

A London number from the Ofcom test range:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+44 20 7946 0958")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "020 7946 0958"}

iex> Localize.PhoneNumber.territory(phone_number)
"GB"

iex> Localize.PhoneNumber.type(phone_number)
:fixed_line
```

### Berlin — The Lives of Others

A Berlin landline in the Mitte district:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+49 30 901820")
iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "030 901820"}

iex> Localize.PhoneNumber.territory(phone_number)
"DE"

iex> Localize.PhoneNumber.type(phone_number)
:fixed_line
```

## The 555 convention

In North America, numbers in the 555-01XX range are officially reserved for fictional use. This means they always parse and validate as real numbers, making them safe for use in examples:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 202-555-0147")
iex> Localize.PhoneNumber.valid?(phone_number)
true

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 415-555-0132")
iex> Localize.PhoneNumber.valid?(phone_number)
true
```

Numbers outside 555-01XX (like the original Ghostbusters 555-2368 or Jenny's 867-5309) are real number ranges that may or may not be allocated to actual subscribers.

## Formatting for different audiences

Once you have a parsed number, the same struct can be formatted for any purpose:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 212-555-2368")
iex> Localize.PhoneNumber.to_string(phone_number, :e164)
{:ok, "+12125552368"}

iex> Localize.PhoneNumber.to_string(phone_number, :international)
{:ok, "+1 212-555-2368"}

iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "(212) 555-2368"}

iex> Localize.PhoneNumber.to_string(phone_number, :rfc3966)
{:ok, "tel:+1-212-555-2368"}
```

* `:e164` for storage in databases and APIs.
* `:international` for display to a global audience.
* `:national` for display within the number's home country.
* `:rfc3966` for `tel:` links in HTML and SIP URIs.
