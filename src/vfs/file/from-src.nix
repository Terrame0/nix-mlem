{
  sundry,
  lib,
  flake-root,
  ...
}: rec {
  from-src = vfs-path: fs-path:
    sundry.attrs.merge.recursive.no-collision [
      (sundry.vfs.file.from-text vfs-path (builtins.readFile fs-path))
      (lib.setAttrByPath vfs-path {origin = fs-path;})
    ];
  tests = [
    [
      (from-src ["abc" "def" "A.txt"] "${flake-root}/tests/vfs-test-dir/test-files/A.txt")
      {
        abc = {
          def = {
            "A.txt" = {
              text = "contents of A.txt";
              origin = "${flake-root}/tests/vfs-test-dir/test-files/A.txt";
            };
          };
        };
      }
    ]
    [
      (sundry.does-throw (from-src [] "${flake-root}/tests/vfs-test-dir/test-files/A.txt"))
      true
    ]
  ];
}
