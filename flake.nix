{
  description = "My custom registry";
  outputs = { ... }: builtins.fromJSON (builtins.readFile ./registry.json);
}
