defimpl Localize.Chars, for: Localize.PhoneNumber.Number do
  @moduledoc false

  # The default format type is `:international`. The `:format`
  # option (if provided) maps to a `Localize.PhoneNumber.to_string/2`
  # format type atom: `:e164`, `:international`, `:national`, or
  # `:rfc3966`.

  def to_string(value) do
    Localize.PhoneNumber.to_string(value, :international)
  end

  def to_string(value, options) do
    format_type = Keyword.get(options, :format, :international)
    Localize.PhoneNumber.to_string(value, format_type)
  end
end
