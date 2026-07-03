{
  lib,
  sundry,
  flake-root,
  pkgs,
  ...
}: rec {
  materialize = drv-name: dir: let
    files =
      sundry.attrs.collapse-until
      sundry.vfs.is-leaf-node
      (path: attrs: {
        inherit path;
        inherit (attrs) text;
      })
      dir;
    cmd =
      lib.foldl (
        cmd-acc: file-attrs: let
          dir = lib.concatStringsSep "/" (lib.init file-attrs.path);
          file-path = lib.concatStringsSep "/" file-attrs.path;
          mk-dir-cmd = "mkdir -p \"$out/${dir}\" \n";
          cp-file-cmd = "printf '%s' '${builtins.replaceStrings ["'"] ["'\\''"] file-attrs.text}' > \"$out/${file-path}\" \n";
        in
          cmd-acc + mk-dir-cmd + cp-file-cmd
      ) ""
      files;
    drv-path = pkgs.runCommand drv-name {} cmd;
  in
    sundry.vfs.dir.walk
    (path: file:
      (removeAttrs file ["text"])
      // {
        origin = sundry.vfs.path.get.str ([drv-path] ++ path);
        inherit drv-path;
      })
    dir;

  tests = [
    [
      (builtins.readFile
        (lib.pipe "${flake-root}/tests/vfs-test-dir/test-files" [
          sundry.vfs.dir.from-src
          (materialize "test-dir")
        ])."A.txt".origin)
      "contents of A.txt"
    ]
    [
      (builtins.readFile
        (lib.pipe "${flake-root}/tests/vfs-test-dir/escaping" [
          sundry.vfs.dir.from-src
          (materialize "escaping-dir")
        ])."A.txt".origin)
      "a'b'c"
    ]
  ];
}
