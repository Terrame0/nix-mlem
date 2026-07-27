args @ {
  lib,
  flake-root,
  sundry,
  pkgs,
  ...
}: let
  merge-attrs = merge-fn: attrs:
    lib.zipAttrsWith (
      name: values:
        lib.foldl
        (acc-value: value: merge-fn name acc-value value)
        (lib.head values)
        (lib.tail values)
    )
    attrs;

  merge-attrs-recursive = let
    merge-fn = name: acc-value: value:
      if lib.isAttrs acc-value && lib.isAttrs value
      then merge-attrs (next-name: merge-fn "${name}.${next-name}") [acc-value value]
      else throw "there is a collision at '${name}'";
  in
    merge-attrs merge-fn;

  module-contents = path: let
    path-str = lib.removeSuffix ".nix" (toString path);
    store-path = "${flake-root}/src/";
    no-store-path = lib.removePrefix store-path path-str;
    functions-path = lib.init (lib.splitString "/" no-store-path);
    functions = removeAttrs (import path (args // {})) ["tests"];
  in
    lib.setAttrByPath functions-path functions;

  module-files =
    lib.filter
    (path: lib.hasSuffix ".nix" path)
    (lib.filesystem.listFilesRecursive ../src);
in
  lib.foldl
  (acc: path: merge-attrs-recursive [acc (module-contents path)])
  {
    attrs = {
      merge-with = merge-attrs;
    };
  }
  module-files
