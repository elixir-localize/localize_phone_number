defimpl String.Chars, for: Localize.PhoneNumber.Number do
  @moduledoc false

  # Returns the E.164 canonical form (`"+15551234567"`).
  #
  # `String.Chars` is the unambiguous, format-independent representation —
  # the locale- or context-aware variants are exposed through
  # `Localize.Chars.to_string/2` and `Localize.PhoneNumber.to_string/2`,
  # which take an explicit `:format`.
  #
  # Mirrors the relationship between `String.Chars` and `Localize.Chars`
  # for `Localize.LanguageTag`: canonical form here, locale-aware display
  # name in `Localize.Chars`.

  def to_string(number) do
    case Localize.PhoneNumber.to_string(number, :e164) do
      {:ok, formatted} -> formatted
      {:error, _reason} -> number.raw_input
    end
  end
end
