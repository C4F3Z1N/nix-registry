{ lib, writeText, include ? { }, source ? ./flake.lock, version ? 2 }:
with builtins // lib;
let
  # detect whether the source is a lock file or an attribute set;
  entries = if (typeOf source) == "path" then
    pipe source [
      (importJSON)
      ({ nodes, ... }:
        # consider only the root inputs;
        mapAttrs (_: path: getAttrFromPath [ (last (flatten path)) ] nodes)
        nodes.root.inputs)
      (filterAttrs (id: { flake ? id != "root", ... }: flake))
    ]
  else if (typeOf source) == "set" then
    source
  else
    throw "Unsupported source type: ${typeOf source}.";
in pipe (entries // include) [
  # detect whether it's a lock entry or flake input;
  (mapAttrs (id:
    { locked ? null, sourceInfo ? null, ... }:
    if !isNull locked then
      locked
    else if !isNull sourceInfo then {
      inherit (sourceInfo) lastModified narHash;
      type = "path";
      path = sourceInfo.outPath;
    } else
      throw "Unsupported entry: ${id}."))
  # create a list in the right format;
  (mapAttrsToList (id: to: {
    inherit to;
    exact = true;
    from = {
      inherit id;
      type = "indirect";
    };
  }))
  (flakes: { inherit flakes version; })
  (toJSON)
  # use writeText because it generates a derivation;
  (writeText "registry.json")
]
