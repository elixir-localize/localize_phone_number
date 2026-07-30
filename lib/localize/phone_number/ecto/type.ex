if Code.ensure_loaded?(Ecto.ParameterizedType) do
  defmodule Localize.PhoneNumber.Ecto.Type do
    @moduledoc """
    An `Ecto.ParameterizedType` storing a phone number as E.164 text.

    A phone number is stored in its E.164 form — `"+16502530000"` — which
    is the one representation that identifies a number unambiguously
    worldwide. That makes the column a natural key: it can carry a unique
    index, be compared for equality, and be matched by prefix to find
    every number in a country, none of which works reliably against a
    number stored the way a person happened to type it.

    Values load as a `t:Localize.PhoneNumber.Number.t/0`, so the loaded
    number formats for display in any style:

        iex> {:ok, number} = Localize.PhoneNumber.parse("+1 650-253-0000")
        iex> Localize.PhoneNumber.to_string(number, :national)
        {:ok, "(650) 253-0000"}

    ### Schema

    The column is ordinary text, so no migration beyond the column
    itself is needed:

        # in a migration
        add :phone, :string
        create unique_index(:contacts, [:phone])

        # in a schema
        field :phone, Localize.PhoneNumber.Ecto.Type

    ### Casting national formats

    A number typed without an international prefix cannot be resolved
    without knowing the country it belongs to. Give the field a
    `:territory` or a `:locale` and locally formatted input casts
    correctly:

        field :phone, Localize.PhoneNumber.Ecto.Type, territory: "GB"

    With no option, the territory comes from `Localize.get_locale/0` at
    the moment of the cast, as in `Localize.PhoneNumber.parse/2`.

    ### Options

    * `:territory` is an ISO 3166-1 alpha-2 territory code used as the
      default territory when casting a number that is not in
      international format.

    * `:locale` is a locale identifier from which the default territory
      is derived.

    """

    use Ecto.ParameterizedType

    alias Localize.PhoneNumber
    alias Localize.PhoneNumber.Number

    @impl true
    def init(options) do
      options
      |> Keyword.take([:territory, :locale])
      |> Map.new()
    end

    @impl true
    def type(_params) do
      :string
    end

    @impl true
    def cast(nil, _params) do
      {:ok, nil}
    end

    def cast("", _params) do
      {:ok, nil}
    end

    def cast(%Number{} = number, _params) do
      {:ok, number}
    end

    def cast(number_string, params) when is_binary(number_string) do
      case PhoneNumber.parse(number_string, parse_options(params)) do
        {:ok, number} -> {:ok, number}
        {:error, reason} -> {:error, message: reason}
      end
    end

    def cast(_other, _params) do
      :error
    end

    # A stored value is already E.164, so it carries its own country
    # code and needs no default territory. The parse rebuilds the
    # native representation that formatting requires.
    @impl true
    def load(nil, _loader, _params) do
      {:ok, nil}
    end

    def load(e164, _loader, _params) when is_binary(e164) do
      case PhoneNumber.parse(e164) do
        {:ok, number} -> {:ok, number}
        {:error, _reason} -> :error
      end
    end

    def load(_other, _loader, _params) do
      :error
    end

    @impl true
    def dump(nil, _dumper, _params) do
      {:ok, nil}
    end

    def dump(%Number{} = number, _dumper, _params) do
      case PhoneNumber.to_string(number, :e164) do
        {:ok, e164} -> {:ok, e164}
        {:error, _reason} -> :error
      end
    end

    def dump(_other, _dumper, _params) do
      :error
    end

    # Compared on the parsed components rather than on the E.164 text so
    # that two numbers written differently — "+1 650-253-0000" and
    # "+16502530000" — are equal without formatting either of them.
    @impl true
    def equal?(%Number{} = left, %Number{} = right, _params) do
      left.country_code == right.country_code and
        left.national_number == right.national_number and
        left.extension == right.extension
    end

    def equal?(left, right, _params) do
      left == right
    end

    # Casting is territory-sensitive, so an embedded number is stored in
    # its dumped E.164 form rather than as a map of components.
    @impl true
    def embed_as(_format, _params) do
      :dump
    end

    defp parse_options(params) do
      params
      |> Map.take([:territory, :locale])
      |> Enum.to_list()
    end
  end
end
