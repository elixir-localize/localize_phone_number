defmodule LocalizePhonenumber.Phonenumber do
  @moduledoc """
  Represents a parsed phone number.

  The struct contains the decomposed fields of a phone number for
  inspection, plus an opaque `__native__` binary that preserves the
  full protobuf representation for lossless round-trips through the
  NIF layer.

  """

  @type t :: %__MODULE__{
          country_code: pos_integer(),
          national_number: pos_integer(),
          extension: String.t() | nil,
          raw_input: String.t(),
          __native__: binary()
        }

  @derive {Inspect, except: [:__native__]}

  defstruct country_code: 0,
            national_number: 0,
            extension: nil,
            raw_input: "",
            __native__: <<>>
end
