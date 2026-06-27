# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — June 27th, 2026

### Adds

* Adds Phoenix.HTML.Safe for Localize.PhoneNumber.Number so a parsed number can render in HEEx and be used as a form input value without raising Protocol.UndefinedError. Thanks to @C-Sinclair for the PR. Closes #2.

## [0.1.0] — April 16th, 2026

### Highlights

Initial release of `Localize.PhoneNumber`, an Elixir NIF wrapper around Google's [libphonenumber](https://github.com/google/libphonenumber) C++ library. The library provides locale-aware phone number handling with territory defaults powered by [Localize](https://github.com/elixir-localize/localize).

* **Parsing** — `Localize.PhoneNumber.parse/2` accepts phone numbers in national or international format. Territory defaults are resolved from an explicit `:territory` option, a `:locale` option, or automatically from `Localize.get_locale/0`.

* **Formatting** — `Localize.PhoneNumber.to_string/2` formats parsed numbers as E.164, international, national, or RFC 3966 strings. Defaults to `:international` format.

* **Validation** — `valid?/1`, `valid_for_territory?/2`, and `possible?/1` check whether a parsed number is valid, valid for a given territory, or has a plausible length.

* **Type detection** — `type/1` classifies a number as `:mobile`, `:fixed_line`, `:toll_free`, `:premium_rate`, `:voip`, and other categories.

* **Territory resolution** — `territory/1` returns the ISO 3166-1 alpha-2 territory code for a parsed number.

See the [README](https://hexdocs.pm/localize_phone_number/readme.html) and the [Parsing and Formatting Guide](https://hexdocs.pm/localize_phone_number/parsing_and_formatting.html) for full documentation and examples.
