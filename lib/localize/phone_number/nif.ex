defmodule Localize.PhoneNumber.Nif do
  @moduledoc """
  NIF interface to Google's libphonenumber C++ library.

  This module provides NIF bindings for phone number parsing,
  formatting, and validation using libphonenumber. The NIF is
  always compiled and loaded as a required dependency.

  Requires the libphonenumber C++ library to be installed on
  the system. On macOS: `brew install libphonenumber`.

  """

  @on_load :init

  @doc false
  def init do
    path = :code.priv_dir(:localize_phone_number) ++ ~c"/localize_phone_number_nif"
    :erlang.load_nif(path, 0)
  end

  @doc """
  Returns whether the NIF backend is available.

  ### Returns

  * `true` if the NIF shared library was loaded successfully.

  * `false` if the NIF is not compiled or libphonenumber libraries are missing.

  ### Examples

      iex> is_boolean(Localize.PhoneNumber.Nif.available?())
      true

  """
  @spec available?() :: boolean()
  def available? do
    match?({:ok, _, _, _, _, _}, nif_parse("+10000000000", "US"))
  rescue
    _ -> false
  end

  # ── Parse ──────────────────────────────────────────────────────

  @doc """
  Parses a phone number string into its component parts.

  ### Arguments

  * `number_string` is the phone number string to parse.

  * `default_territory` is the ISO 3166-1 alpha-2 territory code
    used when the number is not in international format.

  ### Returns

  * `{:ok, country_code, national_number, extension, raw_input, native_binary}`
    on successful parse.

  * `{:error, reason}` if the number cannot be parsed.

  """
  @spec parse(String.t(), String.t()) ::
          {:ok, pos_integer(), pos_integer(), String.t(), String.t(), binary()}
          | {:error, String.t()}
  def parse(number_string, default_territory)
      when is_binary(number_string) and is_binary(default_territory) do
    nif_parse(number_string, default_territory)
  end

  # ── Format ─────────────────────────────────────────────────────

  @doc """
  Formats a phone number in the specified format.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  * `format_type` is one of `"e164"`, `"international"`, `"national"`,
    or `"rfc3966"`.

  ### Returns

  * `{:ok, formatted_string}` on success.

  * `{:error, reason}` on failure.

  """
  @spec format(binary(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def format(native_binary, format_type)
      when is_binary(native_binary) and is_binary(format_type) do
    nif_format(native_binary, format_type)
  end

  # ── Validation ─────────────────────────────────────────────────

  @doc """
  Returns whether a phone number is valid.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  ### Returns

  * `true` if the phone number is valid.

  * `false` otherwise.

  """
  @spec valid?(binary()) :: boolean()
  def valid?(native_binary) when is_binary(native_binary) do
    nif_valid(native_binary)
  end

  @doc """
  Returns whether a phone number is valid for a specific territory.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  * `territory` is the ISO 3166-1 alpha-2 territory code.

  ### Returns

  * `true` if the phone number is valid for the given territory.

  * `false` otherwise.

  """
  @spec valid_for_territory?(binary(), String.t()) :: boolean()
  def valid_for_territory?(native_binary, territory)
      when is_binary(native_binary) and is_binary(territory) do
    nif_valid_for_territory(native_binary, territory)
  end

  @doc """
  Returns whether a phone number is a possible number.

  A possible number has the right length for its type and territory
  but may not actually be allocated.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  ### Returns

  * `true` if the phone number is possible.

  * `false` otherwise.

  """
  @spec possible?(binary()) :: boolean()
  def possible?(native_binary) when is_binary(native_binary) do
    nif_possible(native_binary)
  end

  # ── Type and Territory ─────────────────────────────────────────

  @doc """
  Returns the phone number type.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  ### Returns

  * A string representing the type, such as `"mobile"`, `"fixed_line"`,
    `"fixed_line_or_mobile"`, `"toll_free"`, `"premium_rate"`,
    `"shared_cost"`, `"voip"`, `"personal_number"`, `"pager"`,
    `"uan"`, `"voicemail"`, or `"unknown"`.

  """
  @spec type(binary()) :: String.t()
  def type(native_binary) when is_binary(native_binary) do
    nif_type(native_binary)
  end

  @doc """
  Returns the territory code for a phone number.

  ### Arguments

  * `native_binary` is the opaque binary from a parsed phone number.

  ### Returns

  * A two-letter ISO 3166-1 alpha-2 territory code string
    (e.g., `"US"`, `"GB"`), or an empty string if the territory
    cannot be determined.

  """
  @spec territory(binary()) :: String.t()
  def territory(native_binary) when is_binary(native_binary) do
    nif_territory(native_binary)
  end

  # ── NIF stubs ──────────────────────────────────────────────────

  @dialyzer {:no_return, nif_parse: 2}
  defp nif_parse(_number_string, _default_territory) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_format: 2}
  defp nif_format(_native_binary, _format_type) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_valid: 1}
  defp nif_valid(_native_binary) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_valid_for_territory: 2}
  defp nif_valid_for_territory(_native_binary, _territory) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_possible: 1}
  defp nif_possible(_native_binary) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_type: 1}
  defp nif_type(_native_binary) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_territory: 1}
  defp nif_territory(_native_binary) do
    :erlang.nif_error(:nif_library_not_loaded)
  end
end
