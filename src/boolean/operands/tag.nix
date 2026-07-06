{sundry, ...}: let
  match-base = merge: tag-list: tag-spec:
    sundry.vfs.tag.faceted-match (merge tag-list) tag-spec;
in rec {
  tag = match-base sundry.attrs.merge.concat;
  deepest-tag = match-base sundry.attrs.merge.override;
  tests = let
    tag-list = [{a = "1";} {b = ["1" "2"];}];
    override-list = [{modules = "user";} {a = "1";} {modules = "system";}];
  in [
    [(tag tag-list {a = "1";}) true]
    [(tag tag-list {b = "2";}) true]
    [(tag tag-list ({a = "1";} // {b = "2";})) true]
    [(tag [] {}) true]
    [(tag [] {a = "1";}) false]

    [(deepest-tag override-list {modules = "system";}) true]
    [(deepest-tag override-list {modules = "user";}) false]
    [(deepest-tag override-list {modules = [];}) true]
    [(deepest-tag override-list {absent = "x";}) false]
    [(deepest-tag [{modules = "user";} {a = "1";}] {modules = "user";}) true]
    [(deepest-tag [{modules = ["system" "user"];}] {modules = "user";}) true]
    [(deepest-tag [] {}) true]
    [(deepest-tag [] {modules = "system";}) false]
  ];
}
