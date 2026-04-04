defmodule Localize.PhoneNumber.TerritoryTest do
  use ExUnit.Case

  alias Localize.PhoneNumber.Territory

  describe "resolve/1" do
    test "validates explicit territory string via Localize" do
      assert Territory.resolve(territory: "GB") == "GB"
    end

    test "validates explicit territory atom via Localize" do
      assert Territory.resolve(territory: :GB) == "GB"
    end

    test "extracts territory from locale string via Localize" do
      assert Territory.resolve(locale: "en-US") == "US"
    end

    test "extracts territory from locale atom via Localize" do
      assert Territory.resolve(locale: :en_US) == "US"
    end

    test "extracts territory from locale string with underscore" do
      assert Territory.resolve(locale: "en_GB") == "GB"
    end

    test "extracts territory from script locale string" do
      assert Territory.resolve(locale: "zh-Hans-CN") == "CN"
    end

    test "territory option takes precedence over locale" do
      assert Territory.resolve(territory: "GB", locale: "en-US") == "GB"
    end

    test "resolves territory for language-only locale via Localize" do
      result = Territory.resolve(locale: "en")
      assert is_binary(result)
      assert byte_size(result) == 2 or result == "US"
    end

    test "falls back to default when no options given" do
      result = Territory.resolve([])
      assert is_binary(result)
    end
  end
end
