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
      (path: attrs: let
        text = attrs.text or null;
      in
        if lib.isString text
        then {
          inherit path text;
        }
        else throw "\ncannot materialize a vfs file without text at '/${sundry.vfs.path.get.str path}'")
      dir;
    cmd =
      lib.foldl (
        cmd-acc: file-attrs: let
          dir = sundry.str.join-with "/" (lib.init file-attrs.path);
          file-path = sundry.str.join-with "/" file-attrs.path;
          mk-dir-cmd = "mkdir -p \"$out/${dir}\" \n";
          cp-file-cmd = "printf '%s' '${builtins.replaceStrings ["'"] ["'\\''"] file-attrs.text}' > \"$out/${file-path}\" \n";
        in
          cmd-acc + mk-dir-cmd + cp-file-cmd
      ) ""
      files;
    drv = builtins.deepSeq files (pkgs.runCommand drv-name {} cmd);
  in {
    inherit drv;
    dir =
      sundry.vfs.dir.walk
      (path: file:
        (removeAttrs file ["text"])
        // {
          origin = sundry.vfs.path.get.str ([drv] ++ path);
        })
      dir;
  };

  tests = [
    [
      (builtins.readFile
        (lib.pipe "${flake-root}/tests/vfs-test-dir/test-files" [
          sundry.vfs.dir.from-src
          (materialize "test-dir")
          (result: result.dir)
        ])."A.txt".origin)
      "contents of A.txt"
    ]
    [
      (builtins.readFile
        (lib.pipe "${flake-root}/tests/vfs-test-dir/test-files" [
          sundry.vfs.dir.from-src
          (materialize "test-dir-drv")
          (result: "${result.drv}/A.txt")
        ]))
      "contents of A.txt"
    ]
    [
      (builtins.readFile
        (lib.pipe "${flake-root}/tests/vfs-test-dir/escaping" [
          sundry.vfs.dir.from-src
          (materialize "escaping-dir")
          (result: result.dir)
        ])."A.txt".origin)
      "a'b'c"
    ]
    [
      (sundry.does-throw
        (materialize "missing-text" {
          "A.txt" = {origin = "/tmp/A.txt";};
        }))
      true
    ]
  ];
}
