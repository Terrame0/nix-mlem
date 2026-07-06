{
  sundry,
  flake-root,
  lib,
  ...
}: {
  select-by-tag = expr-fn:
    sundry.vfs.dir.filter
    (path: file: sundry.boolean.expr expr-fn file.tag-list);

  tests = let
    tag-dir = lib.pipe "${flake-root}/tests/vfs-test-dir/tags" [
      sundry.vfs.dir.from-src
      sundry.vfs.dir.resolve-tags
    ];
  in [
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.select-by-tag
          (e: with e; tag {b = "1";})
          tag-dir))
      ["contents of H" "contents of G" "contents of I" "contents of C"]
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.select-by-tag
          (e: with e; !(tag {b = [];}))
          tag-dir))
      ["contents of F" "contents of A" "contents of B" "contents of E"]
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.select-by-tag
          (e: with e; (tag {b = "1";}) || !(tag {b = [];}))
          tag-dir))
      [
        "contents of H"
        "contents of G"
        "contents of F"
        "contents of I"
        "contents of A"
        "contents of B"
        "contents of C"
        "contents of E"
      ]
    ]
  ];
}
