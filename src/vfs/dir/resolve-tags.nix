{
  lib,
  sundry,
  flake-root,
  ...
}: rec {
  resolve-tags =
    sundry.attrs.reform-until
    sundry.vfs.is-leaf-node
    (path: value: {
      path = sundry.vfs.path.strip-between "{" "}" path;
      value =
        value
        // {
          tag-list = map (dir:
            lib.pipe dir [
              (sundry.str.between "{" "}")
              (map (tag-str: let
                tag-parts = sundry.str.split ":" tag-str;
                tag-key = lib.head tag-parts;
                tag-value = sundry.is-null (sundry.list.excl-last tag-parts) "";
                tag-list = sundry.str.split "," tag-value;
              in {
                ${tag-key} = sundry.list.un-singleton tag-list;
              }))
              sundry.attrs.merge.no-collision
            ])
          path;
        };
    });
  tests = [
    [
      (lib.pipe "${flake-root}/tests/vfs-test-dir/tags" [
        sundry.vfs.dir.from-src
        resolve-tags
      ])
      {
        A = {
          text = "contents of A";
          origin = "${flake-root}/tests/vfs-test-dir/tags/A{a:1}";
          tag-list = [{a = "1";}];
        };
        B = {
          text = "contents of B";
          origin = "${flake-root}/tests/vfs-test-dir/tags/B{a:2,3}";
          tag-list = [{a = ["2" "3"];}];
        };
        C = {
          text = "contents of C";
          origin = "${flake-root}/tests/vfs-test-dir/tags/C{a:1}{b:1}";
          tag-list = [({a = "1";} // {b = "1";})];
        };
        D = {
          text = "contents of D";
          origin = "${flake-root}/tests/vfs-test-dir/tags/D{a}{b:}";
          tag-list = [({a = "";} // {b = "";})];
        };
        E = {
          text = "contents of E";
          origin = "${flake-root}/tests/vfs-test-dir/tags/E";
          tag-list = [{}];
        };
        "=" = {
          F = {
            text = "contents of F";
            origin = "${flake-root}/tests/vfs-test-dir/tags/={a:1}/F{a:2}";
            tag-list = [{a = "1";} {a = "2";}];
          };
          I = {
            text = "contents of I";
            origin = "${flake-root}/tests/vfs-test-dir/tags/={b:1}/I{c:1}";
            tag-list = [{b = "1";} {c = "1";}];
          };
          "=" = {
            G = {
              text = "contents of G";
              origin = "${flake-root}/tests/vfs-test-dir/tags/={a:1}/={b:1}/G{b:2}";
              tag-list = [{a = "1";} {b = "1";} {b = "2";}];
            };
            "=" = {
              H = {
                text = "contents of H";
                origin = "${flake-root}/tests/vfs-test-dir/tags/={a:1}/={b:1}/={c:1}/H{c:2}";
                tag-list = [{a = "1";} {b = "1";} {c = "1";} {c = "2";}];
              };
            };
          };
        };
      }
    ]
  ];
}
