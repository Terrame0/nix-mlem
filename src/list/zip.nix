{lib, ...}: rec {
  zip = lib.zipListsWith (a: b: [a b]);
  zip-n = lists:
    lib.foldl
    (acc: list: lib.zipListsWith (tuple: x: tuple ++ [x]) acc list)
    (map lib.singleton (lib.head lists))
    (lib.tail lists);
  tests = [
    [(zip [1 2 3] [4 5]) [[1 4] [2 5]]]
    [(zip-n [[1 2 3] [4 5] [6 7]]) [[1 4 6] [2 5 7]]]
  ];
}
