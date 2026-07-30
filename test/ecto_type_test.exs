defmodule Localize.PhoneNumber.Ecto.TypeTest do
  use ExUnit.Case, async: true

  alias Localize.PhoneNumber
  alias Localize.PhoneNumber.Ecto.Type

  doctest Localize.PhoneNumber.Ecto.Type

  @params Type.init([])
  @gb_params Type.init(territory: "GB")

  describe "type/1" do
    test "stores as text" do
      assert Type.type(@params) == :string
    end
  end

  describe "cast/2" do
    test "casts an E.164 string" do
      assert {:ok, number} = Type.cast("+16502530000", @params)
      assert number.country_code == 1
      assert number.national_number == 6_502_530_000
    end

    test "casts a formatted international string" do
      assert {:ok, number} = Type.cast("+1 650-253-0000", @params)
      assert number.national_number == 6_502_530_000
    end

    test "passes a number struct through" do
      {:ok, number} = PhoneNumber.parse("+16502530000")

      assert Type.cast(number, @params) == {:ok, number}
    end

    test "casts a national format using the field territory" do
      assert {:ok, number} = Type.cast("020 7946 0958", @gb_params)
      assert number.country_code == 44
    end

    test "casts nil and the empty string to nil" do
      assert Type.cast(nil, @params) == {:ok, nil}
      assert Type.cast("", @params) == {:ok, nil}
    end

    test "returns a message for an unparseable string" do
      assert {:error, message: message} = Type.cast("not a phone number", @params)
      assert is_binary(message)
    end

    test "refuses a value that is neither a string nor a number" do
      assert Type.cast(42, @params) == :error
      assert Type.cast(%{country_code: 1}, @params) == :error
    end
  end

  describe "dump/3" do
    test "dumps to E.164" do
      {:ok, number} = PhoneNumber.parse("+1 650-253-0000")

      assert Type.dump(number, nil, @params) == {:ok, "+16502530000"}
    end

    test "dumps a national-format cast to E.164" do
      {:ok, number} = Type.cast("020 7946 0958", @gb_params)

      assert Type.dump(number, nil, @params) == {:ok, "+442079460958"}
    end

    test "dumps nil" do
      assert Type.dump(nil, nil, @params) == {:ok, nil}
    end

    test "refuses a non-number" do
      assert Type.dump("+16502530000", nil, @params) == :error
    end
  end

  describe "load/3" do
    test "loads E.164 text into a number" do
      assert {:ok, number} = Type.load("+16502530000", nil, @params)
      assert number.country_code == 1
      assert number.national_number == 6_502_530_000
    end

    # A stored value carries its own country code, so loading does not
    # depend on the field territory.
    test "loads without a territory regardless of the field options" do
      assert {:ok, number} = Type.load("+442079460958", nil, @params)
      assert number.country_code == 44
    end

    test "loads nil" do
      assert Type.load(nil, nil, @params) == {:ok, nil}
    end

    test "refuses text that is not a phone number" do
      assert Type.load("not a phone number", nil, @params) == :error
    end
  end

  describe "round trips" do
    test "cast, dump and load preserve the number" do
      {:ok, cast} = Type.cast("+1 650-253-0000", @params)
      {:ok, dumped} = Type.dump(cast, nil, @params)
      {:ok, loaded} = Type.load(dumped, nil, @params)

      assert Type.equal?(cast, loaded, @params)
    end

    test "a loaded number formats for display" do
      {:ok, loaded} = Type.load("+16502530000", nil, @params)

      assert PhoneNumber.to_string(loaded, :national) == {:ok, "(650) 253-0000"}
      assert PhoneNumber.to_string(loaded, :international) == {:ok, "+1 650-253-0000"}
    end
  end

  describe "equal?/3" do
    test "numbers written differently are equal" do
      {:ok, spaced} = Type.cast("+1 650-253-0000", @params)
      {:ok, bare} = Type.cast("+16502530000", @params)

      assert Type.equal?(spaced, bare, @params)
    end

    test "different numbers are not equal" do
      {:ok, one} = Type.cast("+16502530000", @params)
      {:ok, other} = Type.cast("+442079460958", @params)

      refute Type.equal?(one, other, @params)
    end

    test "nil equals only nil" do
      {:ok, number} = Type.cast("+16502530000", @params)

      assert Type.equal?(nil, nil, @params)
      refute Type.equal?(number, nil, @params)
    end
  end

  describe "embed_as/2" do
    test "embeds the dumped form" do
      assert Type.embed_as(:json, @params) == :dump
    end
  end
end
