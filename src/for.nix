{sundry, ...}: rec {
  for = args-list: init-state: op: let
    decomposition = sundry.list.zip-to-attrs ["init-id" "step" "cond"] args-list;
    inherit (decomposition) init-id step cond;
    recurse = prev: i:
      if (cond i && !(prev ? break && prev.break))
      then recurse (prev // (op prev i)) (step i)
      else removeAttrs prev ["break"];
  in
    recurse init-state init-id;

  tests = [
    [
      (for [1 (i: i + 1) (i: i <= 10)]
        {acc = 1;}
        (prev: i: {acc = i * prev.acc;}))
      {acc = 3628800;}
    ]
    [
      (for [0 (i: i) (i: i != 0)]
        {value = 0;}
        (prev: i: {value = 10;}))
      {value = 0;}
    ]
    [
      (for [0 (i: i + 1) (i: i < 10)]
        {acc = 1;}
        (prev: i: {
          acc = i;
          break = i == 1;
        }))
      {acc = 1;}
    ]
  ];
}
