{
  sundry,
  flake-root,
  lib,
  ...
}: {
  filter =
    sundry.attrs.filter-until
    sundry.vfs.is-leaf-node;

  filter-within-tag = expr-fn:
    sundry.attrs.filter-matched-until
    (path: file: sundry.boolean.expr expr-fn file.tag-list)
    sundry.vfs.is-leaf-node;

  tests = let
    filter-dir = sundry.vfs.dir.from-src "${flake-root}/tests/vfs-test-dir/filtering";
    tag-dir = lib.pipe "${flake-root}/tests/vfs-test-dir/tags" [
      sundry.vfs.dir.from-src
      sundry.vfs.dir.resolve-tags
    ];
  in [
    [
      (lib.pipe filter-dir [
        (sundry.vfs.dir.filter (path: file:
          sundry.vfs.path.get.ext path
          == "txt"
          || file.text
          == "override"))
        sundry.vfs.dir.path-strs
      ])
      [
        "=/=/E.ini"
        "=/=/G.txt"
        "=/C.txt"
        "A.txt"
        "B.txt"
      ]
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.filter-within-tag
          (e: with e; tag {b = "1";})
          (path: file: false)
          tag-dir))
      [
        "contents of F"
        "contents of A"
        "contents of B"
        "contents of D"
        "contents of E"
      ]
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.filter-within-tag
          (e: with e; tag {b = "1";})
          (path: file: file.text != "contents of H")
          tag-dir))
      [
        "contents of G"
        "contents of F"
        "contents of I"
        "contents of A"
        "contents of B"
        "contents of C"
        "contents of D"
        "contents of E"
      ]
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.filter-within-tag
          (e: with e; tag {a = "1";})
          (path: file: false)
          tag-dir))
      [
        "contents of I"
        "contents of B"
        "contents of D"
        "contents of E"
      ]
    ]
  ];
}
