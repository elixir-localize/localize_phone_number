if Code.ensure_loaded?(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: Localize.PhoneNumber.Number do
    @moduledoc false

    # Renders the localized string from `Localize.Chars` (the international
    # format for a phone number), routed through the `BitString` implementation
    # so the result is escaped. This guards the user-supplied `raw_input`
    # fallback and mirrors the `Phoenix.HTML.Safe` implementation for `Money`
    # in ex_money.
    #
    # Compiled only when the optional `phoenix_html` dependency is present.

    def to_iodata(number) do
      string =
        case Localize.Chars.to_string(number) do
          {:ok, formatted} -> formatted
          {:error, _reason} -> number.raw_input
        end

      Phoenix.HTML.Safe.to_iodata(string)
    end
  end
end
