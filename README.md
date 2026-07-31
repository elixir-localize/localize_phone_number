# Localize.PhoneNumber

Elixir interface to Google's [libphonenumber](https://github.com/google/libphonenumber) C++ library via NIF. Provides phone number parsing, formatting, validation, type detection, and territory resolution with locale-aware defaults powered by [Localize](https://hexdocs.pm/localize).

## Usage

Parse a phone number in international format:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> phone_number.country_code
1
iex> phone_number.national_number
6502530000
```

Parse a national number by supplying a territory or locale:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", territory: "GB")
iex> phone_number.country_code
44

iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", locale: "en-GB")
iex> phone_number.country_code
44
```

When neither `:territory` nor `:locale` is given, the default territory is derived from `Localize.get_locale/0`.

Format a parsed number:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.to_string(phone_number, :e164)
{:ok, "+16502530000"}

iex> Localize.PhoneNumber.to_string(phone_number, :international)
{:ok, "+1 650-253-0000"}

iex> Localize.PhoneNumber.to_string(phone_number, :national)
{:ok, "(650) 253-0000"}

iex> Localize.PhoneNumber.to_string(phone_number, :rfc3966)
{:ok, "tel:+1-650-253-0000"}
```

Validate a number:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
iex> Localize.PhoneNumber.valid?(phone_number)
true

iex> Localize.PhoneNumber.valid_for_territory?(phone_number, "US")
true

iex> Localize.PhoneNumber.possible?(phone_number)
true
```

Detect the number type and territory:

```elixir
iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 800-555-0199")
iex> Localize.PhoneNumber.type(phone_number)
:toll_free

iex> Localize.PhoneNumber.territory(phone_number)
"US"
```

See the [Parsing and Formatting Guide](https://hexdocs.pm/localize_phone_number/parsing_and_formatting.html) for detailed usage examples.

## API Summary

| Function | Description |
|----------|-------------|
| `parse/2` | Parse a phone number string into a struct. |
| `to_string/2` | Format a parsed number (`:e164`, `:international`, `:national`, `:rfc3966`). Default is `:international`. |
| `valid?/1` | Check if a parsed number is valid. |
| `valid_for_territory?/2` | Check if a parsed number is valid for a specific territory. |
| `possible?/1` | Quick check if a number has a plausible length. |
| `type/1` | Detect the number type (`:mobile`, `:fixed_line`, `:toll_free`, etc.). |
| `territory/1` | Get the ISO 3166-1 alpha-2 territory code for a number. |

## Territory Resolution

The `parse/2` function needs a default territory to interpret national-format numbers. The territory is resolved in priority order:

1. Explicit `:territory` option — validated via `Localize.validate_territory/1`.
2. Extracted from the `:locale` option — resolved via `Localize.Territory.territory_from_locale/1`. Accepts a string (`"en-GB"`), atom (`:en_GB`), or `Localize.LanguageTag.t()` struct.
3. Derived from the current process locale via `Localize.get_locale/0`.

## Prerequisites

### System Libraries

Google's libphonenumber C++ library must be installed on the build machine. The NIF is compiled automatically by `elixir_make` during `mix compile`.

**macOS (Homebrew):**

```bash
brew install libphonenumber
```

This installs libphonenumber along with its transitive dependencies (protobuf, abseil, boost, and ICU). The Makefile detects the Homebrew prefix automatically on both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Macs.

**Linux (Debian/Ubuntu):**

```bash
sudo apt-get install libphonenumber-dev libprotobuf-dev protobuf-compiler
```

On distributions that provide a `pkg-config` file for libphonenumber, the Makefile uses it automatically. Otherwise it falls back to standard system library paths.

**Linux (Fedora/RHEL):**

```bash
sudo dnf install libphonenumber-devel protobuf-devel
```

**From source:**

If your distribution does not package libphonenumber, build it from [source](https://github.com/google/libphonenumber/blob/master/cpp/README). Ensure the headers are installed to a standard include path and the shared library is on the linker search path.

### Elixir Dependencies

Add `localize_phone_number` to your `mix.exs`:

```elixir
def deps do
  [
    {:localize_phone_number, "~> 1.0"}
  ]
end
```

The library depends on:

* [`localize`](https://hexdocs.pm/localize) — locale and territory resolution.
* [`elixir_make`](https://hex.pm/packages/elixir_make) — compiles the C++ NIF during `mix compile`.

## Architecture

### NIF Design

The library is a thin Elixir wrapper around a C++ NIF that calls libphonenumber's `PhoneNumberUtil` singleton directly. The NIF is compiled automatically by `elixir_make` during `mix compile`.

```
Localize.PhoneNumber              Public API (parse, to_string, valid?, type, territory)
    │
    ├── Localize.PhoneNumber.Territory   Locale-to-territory resolution via Localize
    │
    └── Localize.PhoneNumber.Nif         NIF loader and Elixir stubs
         │
         └── localize_phone_number_nif.cpp
              │
              └── libphonenumber (PhoneNumberUtil)
```

### Parsed Phone Number Struct

`Localize.PhoneNumber.parse/2` returns a `Localize.PhoneNumber.Number` struct:

```elixir
%Localize.PhoneNumber.Number{
  country_code: 1,
  national_number: 6502530000,
  extension: nil,
  raw_input: "+1 650-253-0000"
}
```

The struct also carries an opaque `__native__` field containing the serialized protobuf representation of the phone number. This binary is passed back to the NIF for all subsequent operations (`to_string/2`, `valid?/1`, `type/1`, etc.), ensuring lossless round-trips that preserve metadata such as Italian leading zeros and preferred formatting hints. The `__native__` field is excluded from `Inspect` output.

### Thread Safety

`PhoneNumberUtil::GetInstance()` returns a process-global singleton that is thread-safe for all read operations. No pooling or mutexes are needed — every NIF call can run concurrently on any BEAM scheduler.

### Build System

The `c_src/Makefile` follows the same pattern used by the `localize` project:

* Generates `env.mk` at build time to discover ERTS include paths.
* Detects the platform (macOS ARM/x86, Linux, FreeBSD) and sets appropriate compiler flags.
* Finds libphonenumber, protobuf, and abseil via `pkg-config` with Homebrew fallback paths on macOS.
* Compiles C++17 with `-O3 -fPIC` and produces a shared library at `priv/localize_phone_number_nif.so`.

## License

[Apache-2.0](https://github.com/elixir-localize/localize_phone_number/blob/v1.0.0/LICENSE.md)
