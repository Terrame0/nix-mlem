{lib, ...}: rec {
  remove-at = i: list:
    (lib.sublist 0 i list) ++ (lib.sublist (i + 1) (lib.length list) list);

  tests = [
    [(remove-at 0 ["A" "B" "C"]) ["B" "C"]]
    [(remove-at 1 ["A" "B" "C"]) ["A" "C"]]
    [(remove-at 2 ["A" "B" "C"]) ["A" "B"]]
    [(remove-at 0 ["A"]) []]
  ];
}
