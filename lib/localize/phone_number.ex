defmodule Localize.PhoneNumber do
  @moduledoc """
  Elixir interface to Google's libphonenumber library via NIF.

  Provides phone number parsing, formatting, and validation with
  locale-aware territory defaults. The default territory is derived
  from `Localize.get_locale/0` using the `localize` dependency.

  All functions operate on `Localize.PhoneNumber.Number` structs
  returned by `parse/2`.

  """

  alias Localize.PhoneNumber.Nif
  alias Localize.PhoneNumber.Number
  alias Localize.PhoneNumber.Territory

  @type t :: Number.t()

  @type format_type :: :e164 | :international | :national | :rfc3966

  @type phone_number_type ::
          :fixed_line
          | :mobile
          | :fixed_line_or_mobile
          | :toll_free
          | :premium_rate
          | :shared_cost
          | :voip
          | :personal_number
          | :pager
          | :uan
          | :voicemail
          | :unknown

  @format_types %{
    e164: "e164",
    international: "international",
    national: "national",
    rfc3966: "rfc3966"
  }

  @doc """
  Returns whether the NIF backend is available.

  ### Returns

  * `true` if the NIF shared library was loaded successfully.

  * `false` if the NIF is not compiled or libphonenumber is missing.

  ### Examples

      iex> is_boolean(Localize.PhoneNumber.available?())
      true

  """
  @spec available?() :: boolean()
  defdelegate available?(), to: Nif

  @doc """
  Parses a phone number string into a `Localize.PhoneNumber.Number` struct.

  ### Arguments

  * `number_string` is the phone number string to parse. It can be in
    national or international format.

  ### Options

  * `:territory` is an explicit ISO 3166-1 alpha-2 territory code
    (e.g., `"US"`, `"GB"`, or an atom like `:US`). Used as the default
    territory when the number is not in international format.

  * `:locale` is a locale identifier used to derive the default territory.
    Accepts a string (e.g., `"en-US"`), an atom (e.g., `:en_US`), or a
    `Localize.LanguageTag.t()` struct. The territory is extracted from
    the locale.

  When neither `:territory` nor `:locale` is given, the territory is
  derived from `Localize.get_locale/0`.

  ### Returns

  * `{:ok, phone_number}` where `phone_number` is a
    `Localize.PhoneNumber.Number` struct.

  * `{:error, reason}` if the number cannot be parsed.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> phone_number.country_code
      1

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("020 7946 0958", territory: "GB")
      iex> phone_number.country_code
      44

  """
  @spec parse(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def parse(number_string, options \\ []) when is_binary(number_string) do
    default_territory = Territory.resolve(options)

    case Nif.parse(number_string, default_territory) do
      {:ok, country_code, national_number, extension, raw_input, native_binary} ->
        phone_number = %Number{
          country_code: country_code,
          national_number: national_number,
          extension: if(extension == "", do: nil, else: extension),
          raw_input: raw_input,
          __native__: native_binary
        }

        {:ok, phone_number}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Formats a parsed phone number in the specified format.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct
    returned by `parse/2`.

  * `format_type` is one of `:e164`, `:international`, `:national`,
    or `:rfc3966`.

  ### Returns

  * `{:ok, formatted_string}` on success.

  * `{:error, reason}` on failure.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.format(phone_number, :e164)
      {:ok, "+16502530000"}

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.format(phone_number, :international)
      {:ok, "+1 650-253-0000"}

  """
  @spec format(t(), format_type()) :: {:ok, String.t()} | {:error, String.t()}
  def format(%Number{__native__: native_binary}, format_type)
      when is_atom(format_type) do
    format_string = Map.fetch!(@format_types, format_type)
    Nif.format(native_binary, format_string)
  end

  @doc """
  Returns whether a parsed phone number is valid.

  A valid number has the correct length and pattern for its territory
  and number type.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct.

  ### Returns

  * `true` if the phone number is valid.

  * `false` otherwise.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.valid?(phone_number)
      true

  """
  @spec valid?(t()) :: boolean()
  def valid?(%Number{__native__: native_binary}) do
    Nif.valid?(native_binary)
  end

  @doc """
  Returns whether a parsed phone number is valid for a specific territory.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct.

  * `territory` is an ISO 3166-1 alpha-2 territory code string
    (e.g., `"US"`, `"GB"`).

  ### Returns

  * `true` if the phone number is valid for the given territory.

  * `false` otherwise.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.valid_for_territory?(phone_number, "US")
      true

  """
  @spec valid_for_territory?(t(), String.t()) :: boolean()
  def valid_for_territory?(%Number{__native__: native_binary}, territory)
      when is_binary(territory) do
    Nif.valid_for_territory?(native_binary, String.upcase(territory))
  end

  @doc """
  Returns whether a parsed phone number is a possible number.

  A possible number has a plausible length for its territory and type
  but may not actually be an allocated or valid number.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct.

  ### Returns

  * `true` if the phone number is possible.

  * `false` otherwise.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.possible?(phone_number)
      true

  """
  @spec possible?(t()) :: boolean()
  def possible?(%Number{__native__: native_binary}) do
    Nif.possible?(native_binary)
  end

  @doc """
  Returns the phone number type.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct.

  ### Returns

  * An atom representing the type: `:fixed_line`, `:mobile`,
    `:fixed_line_or_mobile`, `:toll_free`, `:premium_rate`,
    `:shared_cost`, `:voip`, `:personal_number`, `:pager`,
    `:uan`, `:voicemail`, or `:unknown`.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.type(phone_number)
      :fixed_line_or_mobile

  """
  @spec type(t()) :: phone_number_type()
  def type(%Number{__native__: native_binary}) do
    native_binary
    |> Nif.type()
    |> String.to_existing_atom()
  end

  @doc """
  Returns the territory code for a parsed phone number.

  ### Arguments

  * `phone_number` is a `Localize.PhoneNumber.Number` struct.

  ### Returns

  * A two-letter ISO 3166-1 alpha-2 territory code string
    (e.g., `"US"`, `"GB"`).

  * `nil` if the territory cannot be determined.

  ### Examples

      iex> {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      iex> Localize.PhoneNumber.territory(phone_number)
      "US"

  """
  @spec territory(t()) :: String.t() | nil
  def territory(%Number{__native__: native_binary}) do
    case Nif.territory(native_binary) do
      "" -> nil
      territory -> territory
    end
  end
end
