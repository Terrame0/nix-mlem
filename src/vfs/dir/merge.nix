{sundry, ...}: {
  merge = lhs: rhs: sundry.attrs.merge.directories.no-collision [lhs rhs];
  tests = [
    [
      (sundry.vfs.dir.merge
        {
          A = {
            "B.txt" = {
              text = "b";
            };
          };
        }
        {
          A = {
            "C.txt" = {
              text = "c";
            };
          };
          D = {
            "E.txt" = {
              text = "e";
            };
          };
        })
      {
        A = {
          "B.txt" = {
            text = "b";
          };
          "C.txt" = {
            text = "c";
          };
        };
        D = {
          "E.txt" = {
            text = "e";
          };
        };
      }
    ]
    [
      (sundry.vfs.dir.merge {} {})
      {}
    ]
    [
      (sundry.vfs.dir.merge
        {}
        {
          "A.txt" = {
            text = "a";
          };
        })
      {
        "A.txt" = {
          text = "a";
        };
      }
    ]
    [
      (sundry.does-throw (sundry.vfs.dir.merge
        {
          "A.txt" = {
            text = "a";
          };
        }
        {
          "A.txt" = {
            text = "a";
          };
        }))
      true
    ]
    [
      (sundry.does-throw (sundry.vfs.dir.merge
        {
          A = {
            text = "a";
          };
        }
        {
          A = {
            "B.txt" = {
              text = "b";
            };
          };
        }))
      true
    ]
  ];
}
