{sundry, ...}: rec {
  base.no-conflict = path: lhs: rhs:
    if lhs != rhs
    then
      throw
      ''
        there is a conflict in attrset merge at '${sundry.str.join-with "." path}'
          lhs:
            ${sundry.str.pretty lhs}
          rhs:
            ${sundry.str.pretty rhs}
      ''
    else rhs;
  tests = [
    [(sundry.does-throw (base.no-conflict ["_"] {A = 1;} {A = 2;})) true]
    [(base.no-conflict ["_"] 1 1) 1]
    [
      (sundry.attrs.merge.no-conflict [
        {A = 1;}
        {
          A = 1;
          B = 2;
        }
      ])
      {
        A = 1;
        B = 2;
      }
    ]
  ];
}
