defmodule Localize.PhoneNumber.ConcurrencyTest do
  use ExUnit.Case, async: true

  @moduletag :concurrency

  # A diverse set of numbers that exercise different code paths in the NIF:
  # different countries, format types, valid/invalid, extensions.
  @test_numbers [
    {"+1 650-253-0000", "US"},
    {"+1 800-555-0199", "US"},
    {"+44 20 7946 0958", "GB"},
    {"+33 1 42 68 53 00", "FR"},
    {"+49 30 901820", "DE"},
    {"+81 3-1234-5678", "JP"},
    {"+61 2 5550 1234", "AU"},
    {"+1 212-555-2368", "US"},
    {"+39 06 698 83015", "IT"},
    {"+1 650-253-0000 ext. 456", "US"}
  ]

  @concurrency 200
  @iterations 50

  describe "concurrent parse" do
    test "many processes parsing different numbers simultaneously" do
      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              {number, _territory} = Enum.random(@test_numbers)
              assert {:ok, phone_number} = Localize.PhoneNumber.parse(number)
              assert is_integer(phone_number.country_code)
              assert phone_number.country_code > 0
              assert is_integer(phone_number.national_number)
              assert is_binary(phone_number.raw_input)
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end

    test "many processes parsing the same number simultaneously" do
      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              assert {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
              assert phone_number.country_code == 1
              assert phone_number.national_number == 6_502_530_000
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end

    test "many processes parsing invalid input simultaneously" do
      invalid_inputs = ["not a number", "abc", "!!!", "", "---"]

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              input = Enum.random(invalid_inputs)
              assert {:error, reason} = Localize.PhoneNumber.parse(input)
              assert is_binary(reason)
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end
  end

  describe "concurrent format" do
    test "many processes formatting in all four formats simultaneously" do
      {:ok, phone_number} = Localize.PhoneNumber.parse("+1 650-253-0000")
      formats = [:e164, :international, :national, :rfc3966]

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              format = Enum.random(formats)
              assert {:ok, formatted} = Localize.PhoneNumber.to_string(phone_number, format)
              assert is_binary(formatted)
              assert byte_size(formatted) > 0
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end

    test "many processes formatting different numbers simultaneously" do
      phone_numbers =
        for {number, _territory} <- @test_numbers do
          {:ok, phone_number} = Localize.PhoneNumber.parse(number)
          phone_number
        end

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              phone_number = Enum.random(phone_numbers)
              assert {:ok, formatted} = Localize.PhoneNumber.to_string(phone_number, :e164)
              assert String.starts_with?(formatted, "+")
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end
  end

  describe "concurrent validation" do
    test "many processes validating simultaneously" do
      phone_numbers =
        for {number, _territory} <- @test_numbers do
          {:ok, phone_number} = Localize.PhoneNumber.parse(number)
          phone_number
        end

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              phone_number = Enum.random(phone_numbers)
              assert is_boolean(Localize.PhoneNumber.valid?(phone_number))
              assert is_boolean(Localize.PhoneNumber.possible?(phone_number))
              assert is_boolean(Localize.PhoneNumber.valid_for_territory?(phone_number, "US"))
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end
  end

  describe "concurrent type and territory" do
    test "many processes querying type and territory simultaneously" do
      phone_numbers =
        for {number, _territory} <- @test_numbers do
          {:ok, phone_number} = Localize.PhoneNumber.parse(number)
          phone_number
        end

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              phone_number = Enum.random(phone_numbers)

              type = Localize.PhoneNumber.type(phone_number)
              assert is_atom(type)

              territory = Localize.PhoneNumber.territory(phone_number)
              assert is_binary(territory) or is_nil(territory)
            end
          end)
        end

      Task.await_many(tasks, 30_000)
    end
  end

  describe "concurrent mixed operations" do
    test "many processes performing all operations simultaneously" do
      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              {number, _territory} = Enum.random(@test_numbers)

              # Parse
              {:ok, phone_number} = Localize.PhoneNumber.parse(number)

              # Format in a random format
              format = Enum.random([:e164, :international, :national, :rfc3966])
              {:ok, formatted} = Localize.PhoneNumber.to_string(phone_number, format)
              assert is_binary(formatted)

              # Validate
              assert is_boolean(Localize.PhoneNumber.valid?(phone_number))
              assert is_boolean(Localize.PhoneNumber.possible?(phone_number))

              # Type and territory
              assert is_atom(Localize.PhoneNumber.type(phone_number))
              territory = Localize.PhoneNumber.territory(phone_number)
              assert is_binary(territory) or is_nil(territory)
            end
          end)
        end

      Task.await_many(tasks, 60_000)
    end

    test "parse and format interleaved with error cases" do
      inputs =
        Enum.map(@test_numbers, fn {number, _} -> number end) ++
          ["not a number", "abc", "!!!"]

      tasks =
        for _ <- 1..@concurrency do
          Task.async(fn ->
            for _ <- 1..@iterations do
              input = Enum.random(inputs)

              case Localize.PhoneNumber.parse(input) do
                {:ok, phone_number} ->
                  {:ok, _} = Localize.PhoneNumber.to_string(phone_number, :e164)
                  Localize.PhoneNumber.valid?(phone_number)
                  Localize.PhoneNumber.type(phone_number)
                  Localize.PhoneNumber.territory(phone_number)

                {:error, reason} ->
                  assert is_binary(reason)
              end
            end
          end)
        end

      Task.await_many(tasks, 60_000)
    end
  end
end
