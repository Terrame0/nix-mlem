{
  lib,
  sundry,
  ...
}: rec {
  switch = value: cases: let
    recurse = left: let
      case = lib.head left;
      expected = sundry.list.at 0 case;
      result = sundry.list.at 1 case;
    in
      if lib.length left == 1
      then lib.head left
      else if
        if lib.isFunction expected
        then expected value
        else sundry.list.contains expected value
      then result
      else recurse (lib.tail left);
  in
    recurse cases;

  tests = [
    [
      (switch "B" [
        [["A"] "1"]
        [["B"] "2"]
        "3"
      ])
      "2"
    ]
    [
      (switch "C" [
        [["A"] "1"]
        [["B"] "2"]
        "3"
      ])
      "3"
    ]
    [
      (switch "B" [
        [["A" "B"] "1"]
        "2"
      ])
      "1"
    ]
    [
      (switch 5 [
        [(x: x > 3) "1"]
        "2"
      ])
      "1"
    ]
  ];
}
