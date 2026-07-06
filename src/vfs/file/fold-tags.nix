{
  sundry,
  lib,
  ...
}: rec {
  fold-tags = fn: init: file:
    lib.pipe file.tag-list [
      (sundry.list.zip (sundry.range [(lib.length file.tag-list)]))
      (lib.foldl (acc: pair: let
        decomposed = sundry.list.zip-to-attrs ["id" "value"] pair;
        inherit (decomposed) id value;
      in
        fn acc value id)
      init)
    ];

  tests = let
    file = {tag-list = [({A = 1;} // {B = 2;}) {C = 3;}];};
  in [
    [
      (fold-tags (acc: tags: id: acc ++ [[tags id]]) [] file)
      [[({A = 1;} // {B = 2;}) 0] [{C = 3;} 1]]
    ]
    [
      (fold-tags (acc: tags: id: acc ++ [id]) [] file)
      [0 1]
    ]
    [
      (fold-tags (acc: tags: id: acc // tags) {} file)
      ({A = 1;} // {B = 2;} // {C = 3;})
    ]
    [
      (fold-tags (acc: tags: id: acc ++ [id]) [] {tag-list = [];})
      []
    ]
  ];
}
