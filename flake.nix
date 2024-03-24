{ outputs = { ... }: (builtins.fromJSON (builtins.readFile ./registry.json)); }
