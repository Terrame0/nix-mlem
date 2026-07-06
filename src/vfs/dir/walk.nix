{
  lib,
  sundry,
  flake-root,
  ...
}: {
  walk =
    sundry.attrs.walk-until
    sundry.vfs.is-leaf-node;

  walk-within-tag = expr-fn:
    sundry.attrs.walk-matched-until
    (path: file: sundry.boolean.expr expr-fn file.tag-list)
    sundry.vfs.is-leaf-node;

  tests = let
    test-dir = sundry.vfs.dir.from-src "${flake-root}/tests/vfs-test-dir/test-files";
    tag-dir = lib.pipe "${flake-root}/tests/vfs-test-dir/tags" [
      sundry.vfs.dir.from-src
      sundry.vfs.dir.resolve-tags
    ];
  in [
    [
      (sundry.vfs.dir.walk (path: file: {text = "walked ${file.text}";}) test-dir)
      {
        "A.txt" = {text = "walked contents of A.txt";};
        "B.txt" = {text = "walked contents of B.txt";};
        "=" = {"C.txt" = {text = "walked contents of C.txt";};};
      }
    ]
    [
      (sundry.vfs.dir.collapse
        (path: file: file.text)
        (sundry.vfs.dir.walk-within-tag
          (e: with e; tag {b = "1";})
          (path: file: file // {text = "walked ${file.text}";})
          tag-dir))
      [
        "walked contents of H"
        "walked contents of G"
        "contents of F"
        "walked contents of I"
        "contents of A"
        "contents of B"
        "walked contents of C"
        "contents of D"
        "contents of E"
      ]
    ]
  ];
}
