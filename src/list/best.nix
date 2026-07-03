{
  sundry,
  lib,
  ...
}: rec {
  best = base: list:
    if lib.length list < 1
    then throw "the list must have at least a single element"
    else
      lib.foldl
      (acc: value:
        if (base acc value)
        then acc
        else value)
      (lib.head list)
      (lib.tail list);
  tests = [
    [(best (lhs: rhs: lhs < rhs) [4]) 4]
    [(best (lhs: rhs: lhs < rhs) [1 2 3 4]) 1]
    [(sundry.does-throw (best (lhs: rhs: true) [])) true]
  ];
}
