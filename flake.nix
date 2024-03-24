{
  outputs = { ... }:
    let
      raw = builtins.readFile ./registry.json;
      rendered = builtins.fromJSON raw;
      nameValueList = map ({ from, ... }@value: {
        inherit value;
        name = from.id;
      }) rendered.flakes;
    in {
      inherit raw rendered;
      final = builtins.listToAttrs nameValueList;
    };
}
