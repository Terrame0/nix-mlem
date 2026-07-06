{lib, ...}: rec {
  to-segments = sep: string:
    if string == ""
    then []
    else lib.splitString sep string;

  tests = [
    [(to-segments "/" "A/B/C") ["A" "B" "C"]]
    [(to-segments "/" "A") ["A"]]
    [(to-segments "/" "") []]
  ];
}
