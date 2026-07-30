# Credo configuration for Localize.PhoneNumber.
#
# Mirrors the Localize policy: strict, with `Design.AliasUsage`
# disabled. Phone number code fully qualifies many calls because module
# names such as `Localize.PhoneNumber.Number` and `Localize.Territory`
# read more clearly at the call site than an alias, and because trailing
# segments such as `List` and `String` shadow the standard library when
# aliased. Alias Localize submodules opportunistically where the
# trailing segment does not clash, never as a bulk conversion.
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"]
      },
      checks: %{
        disabled: [
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}
