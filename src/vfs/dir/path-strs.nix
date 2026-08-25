{
  sundry,
  flake-root,
  ...
}: rec {
  path-strs = dir:
    sundry.attrs.collapse-until
    sundry.vfs.is-leaf-node
    (path: _: sundry.vfs.path.get.str path)
    dir;
  tests = [
    [
      (path-strs (sundry.vfs.dir.from-src "${flake-root}/tests/vfs-test-dir/test-files"))
      [
        "=/C.txt"
        "A.txt"
        "B.txt"
      ]
    ]
    [
      (sundry.does-throw (path-strs {
        invalid = "abc";
      }))
      true
    ]
  ];
}
