{
  sundry,
  lib,
  flake-root,
  ...
}: rec {
  load-nix-with = fn:
    sundry.vfs.dir.walk
    (path: file: file // {expr = fn path file (import file.origin);});

  load-nix =
    load-nix-with
    (path: file: expr: expr);

  tests = let
    dir = sundry.vfs.dir.from-src "${flake-root}/tests/vfs-test-dir/nix";
  in [
    [
      (lib.pipe dir [
        (load-nix-with (path: file: expr: expr path))
        (sundry.vfs.dir.collapse (path: file: file.expr))
      ])
      [{a = ["A.nix"];} {b = ["B.nix"];} {c = ["C.txt"];}]
    ]
  ];
}
