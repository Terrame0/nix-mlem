{lib, ...}: rec {
  insert-at = i: x: list:
    (lib.sublist 0 i list) ++ (lib.toList x) ++ (lib.sublist i (lib.length list) list);

  tests = [
    [(insert-at 0 "A" ["B" "C"]) ["A" "B" "C"]]
    [(insert-at 1 "A" ["B" "C"]) ["B" "A" "C"]]
    [(insert-at 2 "A" ["B" "C"]) ["B" "C" "A"]]
    [(insert-at 0 "A" []) ["A"]]
    [(insert-at 1 ["A" "B"] ["C" "D"]) ["C" "A" "B" "D"]]
    [(insert-at 0 [] ["A"]) ["A"]]
  ];
}
