{sundry, ...}: let
  find-nth-base = fn: init-offset: step: n: seq: str:
    if n == 0
    then null
    else
      (
        sundry.for [0 (i: i < n) (i: i + 1)]
        {offset = init-offset;}
        (prev: i: rec {
          offset = fn (step prev.offset) seq str;
          break = offset == null;
        })
      ).offset;
in rec {
  find-nth = n: seq: str:
    find-nth-base
    sundry.str.find-after
    (-1)
    (offset: offset + 1)
    n
    seq
    str;
  rfind-nth = n: seq: str:
    find-nth-base
    sundry.str.rfind-after
    (sundry.str.len str - sundry.str.len seq + 1)
    (offset: offset - 1)
    n
    seq
    str;
  tests = [
    [(find-nth 1 "A" "ABAB") 0]
    [(find-nth 2 "A" "ABAB") 2]
    [(find-nth 1 "AB" "ABABAB") 0]
    [(find-nth 2 "AB" "ABABAB") 2]
    [(find-nth 3 "A" "ABAB") null]
    [(find-nth 0 "A" "ABAB") null]

    [(rfind-nth 1 "A" "ABAB") 2]
    [(rfind-nth 2 "A" "ABAB") 0]
    [(rfind-nth 1 "AB" "ABABAB") 4]
    [(rfind-nth 2 "AB" "ABABAB") 2]
    [(rfind-nth 3 "A" "ABAB") null]
    [(rfind-nth 0 "A" "ABAB") null]
  ];
}
