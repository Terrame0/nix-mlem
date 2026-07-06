{
  sundry,
  lib,
  ...
}: rec {
  foldl = fn: init: tag-list:
    lib.pipe tag-list [
      (sundry.list.zip (sundry.range [(lib.length tag-list)]))
      (lib.foldl (acc: pair: let
        decomposed = sundry.list.zip-to-attrs ["id" "value"] pair;
        inherit (decomposed) id value;
      in
        fn acc value id)
      init)
    ];

  tests = let
    tag-list = [({A = 1;} // {B = 2;}) {C = 3;}];
  in [
    [
      (foldl (acc: tags: id: acc ++ [[tags id]]) [] tag-list)
      [[({A = 1;} // {B = 2;}) 0] [{C = 3;} 1]]
    ]
    [
      (foldl (acc: tags: id: acc ++ [id]) [] tag-list)
      [0 1]
    ]
    [
      (foldl (acc: tags: id: acc // tags) {} tag-list)
      ({A = 1;} // {B = 2;} // {C = 3;})
    ]
    [
      (foldl (acc: tags: id: acc ++ [id]) [] [])
      []
    ]
  ];
}
