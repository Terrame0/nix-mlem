{
  lib,
  sundry,
  ...
}: rec {
  faceted-match = tag-set: tag-spec: let
    diff = sundry.attrs.compare tag-set tag-spec;
    present = diff.missing == {};
    matched =
      lib.all lib.id
      (lib.mapAttrsToList (key: pair: let
        decomposed = sundry.list.zip-to-attrs ["values" "wanted-values"] pair;
        inherit (decomposed) values wanted-values;
      in
        wanted-values == [] || sundry.list.intersect (lib.toList values) (lib.toList wanted-values) != [])
      diff.matched);
  in
    present && matched;

  tests = let
    tag-set = {a = "1";} // {b = ["1" "2"];};
  in [
    [(faceted-match tag-set {a = "1";}) true]
    [(faceted-match tag-set {b = "2";}) true]
    [(faceted-match tag-set {a = "9";}) false]
    [(faceted-match tag-set {c = "1";}) false]
    [(faceted-match tag-set {a = [];}) true]
    [(faceted-match tag-set {c = [];}) false]
    [(faceted-match tag-set ({a = "1";} // {b = "9";})) false]
    [(faceted-match tag-set {b = ["9" "2"];}) true]
    [(faceted-match tag-set {a = ["9" "1"];}) true]
    [(faceted-match tag-set {}) true]
    [(faceted-match {} {}) true]
    [(faceted-match {} {a = "1";}) false]
  ];
}
