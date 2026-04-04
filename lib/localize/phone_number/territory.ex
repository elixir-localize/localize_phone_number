defmodule Localize.PhoneNumber.Territory do
  @moduledoc false

  @default_territory "US"

  @doc false
  @spec resolve(keyword()) :: String.t()
  def resolve(options) do
    cond do
      territory = Keyword.get(options, :territory) ->
        validate_territory(territory)

      locale = Keyword.get(options, :locale) ->
        territory_from_locale(locale)

      true ->
        territory_from_default_locale()
    end
  end

  # Use Localize.validate_territory/1 for atom and string territory values.
  defp validate_territory(territory) when is_atom(territory) or is_binary(territory) do
    case Localize.validate_territory(territory) do
      {:ok, territory_atom} ->
        territory_atom |> Atom.to_string() |> String.upcase()

      {:error, _} ->
        @default_territory
    end
  end

  # Use Localize.Territory.territory_from_locale/1 for all locale forms
  # (LanguageTag.t, string, or atom).
  defp territory_from_locale(locale) do
    case Localize.Territory.territory_from_locale(locale) do
      {:ok, territory_atom} ->
        territory_atom |> Atom.to_string() |> String.upcase()

      {:error, _} ->
        @default_territory
    end
  end

  # Derive territory from Localize.get_locale/0 when no options are given.
  defp territory_from_default_locale do
    locale = Localize.get_locale()

    case Localize.Territory.territory_from_locale(locale) do
      {:ok, territory_atom} ->
        territory_atom |> Atom.to_string() |> String.upcase()

      {:error, _} ->
        @default_territory
    end
  end
end
