{
  lib,
  sundry,
  ...
}: rec {
  directories = resolve-next: path: acc-value: value: let
    nodes-are-leaves = map (sundry.vfs.is-leaf-node path) [value acc-value];
  in
    # -- first we handle a leaf/leaf collision (both are leaves)
    if lib.all lib.id nodes-are-leaves
    then resolve-next path acc-value value
    # -- then we handle a leaf/dir collision (one is a leaf, one is a directory)
    # -- with leaf/leaf handled, 'any' distinguishes a mixed collision from dir/dir
    else if lib.any lib.id nodes-are-leaves
    then throw "there is a directory to leaf collision at '/${sundry.vfs.path.get.str path}'"
    else sundry.attrs.merge-with (next-path: directories resolve-next (path ++ next-path)) [acc-value value];
  tests = [
    [
      # -- both are directories
      (sundry.attrs.merge.directories.override [
        {
          A = {
            B = {
              text = "b";
              origin = "/A/B";
            };
          };
        }
        {
          A = {
            C = {
              text = "c";
              origin = "/A/C";
            };
          };
        }
      ])
      {
        A = {
          B = {
            origin = "/A/B";
            text = "b";
          };
          C = {
            origin = "/A/C";
            text = "c";
          };
        };
      }
    ]
    [
      # -- both are leaves
      (sundry.attrs.merge.directories.override [
        {
          A = {
            text = "old";
            origin = "/A";
          };
        }
        {
          A = {
            text = "new";
          };
        }
      ])
      {
        A = {
          text = "new";
        };
      }
    ]
    [
      # -- one node is invalid
      (sundry.does-throw (sundry.attrs.merge.directories.override [
        {
          A = {
            unexpected-attribute = "abc";
          };
        }
        {
          A = {
            text = "new";
          };
        }
      ]))
      true
    ]
    [
      # -- directory to leaf collision
      (sundry.does-throw (sundry.attrs.merge.directories.override [
        {
          A = {
            text = "a";
            origin = "/A";
          };
        }
        {
          A = {
            B = {
              text = "b";
              origin = "/A/B";
            };
          };
        }
      ]))
      true
    ]
  ];
}
