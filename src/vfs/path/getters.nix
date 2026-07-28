{
  lib,
  sundry,
  ...
}: rec {
  get = rec {
    name = path:
      if path == []
      then throw "\nan empty path has no name"
      else lib.last path;
    name-split = path:
      sundry.str.split "." (name path);
    stem = path:
      sundry.str.join-with "."
      (sundry.list.incl-init (name-split path));
    ext = path:
      sundry.is-null
      (sundry.list.excl-last (name-split path)) "";
    str = path:
      if path != []
      then
        lib.foldl (
          str-acc: dir: "${sundry.str.trim-right "/" str-acc}/${sundry.str.trim-left "/" dir}"
        ) (lib.head path)
        (lib.tail path)
      else "";
  };
  tests = [
    [(get.name ["A" "B" "C.txt"]) "C.txt"]
    [(get.stem ["A" "B" "C.txt"]) "C"]
    [(get.ext ["A" "B" "C.txt"]) "txt"]
    [(get.str ["A" "B"]) "A/B"]
    [(get.str ["/A/" "/B"]) "/A/B"]
    [(get.str ["//A//" "//B//" "//C//"]) "//A/B/C//"]
    [(get.str []) ""]
    [(sundry.does-throw (get.name [])) true]
    [(sundry.does-throw (get.stem [])) true]
    [(sundry.does-throw (get.ext [])) true]
  ];
}
