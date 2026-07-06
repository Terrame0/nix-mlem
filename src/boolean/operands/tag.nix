{
  lib,
  sundry,
  ...
}: {
  tag = tag-set: tag-spec: let
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
}
