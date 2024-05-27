{
  lib,
  writeText,
  include ? {},
  source ? ./flake.lock,
}:
with lib; let
  sanitize = entry @ {
    original ? {},
    locked ? {},
    sourceInfo ? {},
    ...
  }:
    if types.isType "flake" entry
    then {
      inherit (sourceInfo) lastModified narHash;
      type = "path";
      path = sourceInfo.outPath;
    }
    else if (original // locked) != {}
    then
      if original ? ref
      then original
      else if locked ? ref
      then
        removeAttrs locked [
          "lastModified"
          "narHash"
          "rev"
          "revCount"
          "shortRev"
        ]
      else locked
    else {};

  entries =
    if (builtins.typeOf source) == "path"
    then
      pipe source [
        importJSON
        ({nodes, ...}:
          builtins.mapAttrs
          (_: path: getAttrFromPath [(last (flatten path))] nodes)
          nodes.root.inputs)
        (filterAttrs (id: {flake ? id != "root", ...}: flake))
      ]
    else if (builtins.typeOf source) == "set"
    then source
    else throw "Unsupported source type: ${builtins.typeOf source}.";
in
  pipe (entries // include) [
    (builtins.mapAttrs (_: sanitize))
    (mapAttrsToList (id: to: {
      inherit to;
      exact = true;
      from = {
        inherit id;
        type = "indirect";
      };
    }))
    (flakes: {
      inherit flakes;
      version = 2;
    })
    (builtins.toJSON)
    (writeText "registry.json")
  ]
