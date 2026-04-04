defmodule Localize.PhoneNumberTest do
  use ExUnit.Case

  describe "available?/0" do
    test "returns a boolean" do
      assert is_boolean(Localize.PhoneNumber.available?())
    end
  end

  describe "parse/2" do
    test "parses an international number" do
      assert {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert phone_number.country_code == 1
      assert phone_number.national_number == 6_502_530_000
    end

    test "parses a national number with explicit territory" do
      assert {:ok, phone_number} =
               Localize.PhoneNumber.parse("020 7946 0958", territory: "GB")

      assert phone_number.country_code == 44
      assert phone_number.national_number == 2_079_460_958
    end

    test "parses a national number with territory as atom" do
      assert {:ok, phone_number} =
               Localize.PhoneNumber.parse("020 7946 0958", territory: :GB)

      assert phone_number.country_code == 44
    end

    test "parses a number with locale option" do
      assert {:ok, phone_number} =
               Localize.PhoneNumber.parse("020 7946 0958", locale: "en-GB")

      assert phone_number.country_code == 44
    end

    test "parses a number with locale atom option" do
      assert {:ok, phone_number} =
               Localize.PhoneNumber.parse("020 7946 0958", locale: :en_GB)

      assert phone_number.country_code == 44
    end

    test "returns error for invalid number" do
      assert {:error, reason} = Localize.PhoneNumber.parse("not a number")
      assert is_binary(reason)
    end

    test "preserves extension when present" do
      assert {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000 ext. 123")
      assert phone_number.extension == "123"
    end

    test "extension is nil when not present" do
      assert {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert phone_number.extension == nil
    end

    test "preserves raw input" do
      assert {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert phone_number.raw_input == "+1 650-253-0000"
    end
  end

  describe "format/2" do
    setup do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      %{phone_number: phone_number}
    end

    test "formats as E.164", %{phone_number: phone_number} do
      assert {:ok, "+16502530000"} = Localize.PhoneNumber.format(phone_number, :e164)
    end

    test "formats as international", %{phone_number: phone_number} do
      assert {:ok, formatted} = Localize.PhoneNumber.format(phone_number, :international)
      assert formatted =~ "+"
      assert formatted =~ "650"
    end

    test "formats as national", %{phone_number: phone_number} do
      assert {:ok, formatted} = Localize.PhoneNumber.format(phone_number, :national)
      assert formatted =~ "650"
      refute String.starts_with?(formatted, "+")
    end

    test "formats as RFC 3966", %{phone_number: phone_number} do
      assert {:ok, formatted} = Localize.PhoneNumber.format(phone_number, :rfc3966)
      assert String.starts_with?(formatted, "tel:")
    end
  end

  describe "valid?/1" do
    test "returns true for a valid number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert Localize.PhoneNumber.valid?(phone_number)
    end

    test "returns false for an invalid number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 21212", territory: "US")
      refute Localize.PhoneNumber.valid?(phone_number)
    end
  end

  describe "valid_for_territory?/2" do
    test "returns true when number matches territory" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert Localize.PhoneNumber.valid_for_territory?(phone_number, "US")
    end

    test "returns false when number does not match territory" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      refute Localize.PhoneNumber.valid_for_territory?(phone_number, "GB")
    end
  end

  describe "possible?/1" do
    test "returns true for a possible number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert Localize.PhoneNumber.possible?(phone_number)
    end
  end

  describe "type/1" do
    test "returns a phone number type atom" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      type = Localize.PhoneNumber.type(phone_number)

      assert type in [
               :fixed_line,
               :mobile,
               :fixed_line_or_mobile,
               :toll_free,
               :premium_rate,
               :shared_cost,
               :voip,
               :personal_number,
               :pager,
               :uan,
               :voicemail,
               :unknown
             ]
    end

    test "detects a toll-free number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 800-555-0199")
      assert Localize.PhoneNumber.type(phone_number) == :toll_free
    end
  end

  describe "territory/1" do
    test "returns the territory for a US number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      assert Localize.PhoneNumber.territory(phone_number) == "US"
    end

    test "returns the territory for a UK number" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+44 20 7946 0958")
      assert Localize.PhoneNumber.territory(phone_number) == "GB"
    end

    test "returns non-geographic code for international numbers" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+800 12345678")
      assert Localize.PhoneNumber.territory(phone_number) == "001"
    end
  end
end
