{
  lib,
  sundry,
  ...
}: rec {
  from-str = path-str:
    sundry.str.to-segments "/"
    (sundry.str.trim-left "/"
      (builtins.unsafeDiscardStringContext (toString path-str)));
  tests = [
    [
      (from-str "/A/B/C.txt")
      ["A" "B" "C.txt"]
    ]
    [(from-str "A/B") ["A" "B"]]
    [(from-str "") []]
  ];
}
