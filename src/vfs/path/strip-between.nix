{
  sundry,
  lib,
  ...
}: rec {
  strip-between = lsep: rsep:
    map (path: "${sundry.str.join (sundry.str.outside lsep rsep path)}");
  tests = [
    [(strip-between "<" ">" ["A<X>" "B<Y>" "C<Z>"]) ["A" "B" "C"]]
    [(strip-between "<" ">" ["NOMARKER" "A<X>"]) ["NOMARKER" "A"]]
    [(strip-between "<" ">" ["A<B<C>D>E"]) ["AE"]]
  ];
}
