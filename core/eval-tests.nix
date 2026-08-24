args @ {
  pkgs,
  lib,
  sundry,
  ...
}: let
  parse-test = module-path: dir-path: id: result: let
    mk-meta = extension:
      extension
      // {
        source =
          lib.removePrefix
          (sundry.str.join-with "/" (lib.init (sundry.str.split "/" (toString dir-path))))
          (toString module-path);
        number = id + 1;
      };
  in
    if lib.length result == 1
    then {
      meta = mk-meta {
        type = "debug";
        print = true;
      };
      value = lib.elemAt result 0;
    }
    else rec {
      meta = mk-meta {
        type = "check";
        print = got != expected;
      };
      got = lib.head result;
      expected = lib.last result;
    };

  parse-module = {
    eval-fn,
    dir-path,
    ...
  }: module-path:
    lib.imap0
    (id: result: parse-test module-path dir-path id result)
    (eval-fn (import module-path args));

  glob-tests = combinator-args @ {dir-path, ...}:
    lib.concatMap
    (path: parse-module combinator-args path)
    (lib.filter
      (path: lib.hasSuffix ".nix" path)
      (lib.filesystem.listFilesRecursive dir-path));

  parsed-tests = lib.concatMap glob-tests [
    {
      eval-fn = imported:
        if imported ? tests
        then imported.tests
        else [];
      dir-path = ../src;
    }
  ];

  format-tests = test: let
    get-lines = str: sundry.str.split "\n" str;
    join-lines = lines: sundry.str.join-with "\n" lines;
    pretty = sundry.str.pretty;

    blocks =
      lib.mapAttrs
      (name: value:
        ["+----[ ${name} ]"]
        ++ (get-lines (pretty value))
        ++ ["+"])
      (removeAttrs test ["meta"]);

    block-line-map = fn:
      lib.mapAttrs (name: value: map (fn name) value) blocks;

    table-width =
      lib.foldl
      (max: line: lib.max max (sundry.str.len line))
      0
      (lib.concatLists (lib.attrValues blocks));

    pad = char: offset:
      (sundry.for
        [offset (i: i < table-width) (i: i + 1)]
        {str = "";}
        (state: i: {str = state.str + char;})).str;

    pad-right = name: line:
      if lib.hasPrefix "+" line
      then "${line}${pad "-" (sundry.str.len line - 3)}+"
      else "| ${line}${pad " " (sundry.str.len line)} |";

    padded-blocks = block-line-map pad-right;

    blocks-str =
      sundry.str.join-with "\n\n"
      (lib.mapAttrsToList (name: block: join-lines block) padded-blocks);
  in ''
    < test №${toString test.meta.number} (${test.meta.type}) from '${test.meta.source}' >

    ${blocks-str}
  '';

  test-results =
    lib.concatMap
    (test:
      if test.meta.print
      then [(format-tests test)]
      else [])
    parsed-tests;
in
  test-results
