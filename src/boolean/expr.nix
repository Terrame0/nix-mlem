{sundry, ...}: rec {
  expr = fn: bound:
    fn (sundry.attrs.walk (_: fn: fn bound) sundry.boolean.operands);
  tests = let
    tag-list = [{a = "1";} {b = ["1" "2"];}];
  in [
    [(expr (o: o.tag {a = "1";}) tag-list) true]
    [(expr (o: o.tag {b = "2";}) tag-list) true]
    [(expr (o: o.tag {a = "9";}) tag-list) false]
    [(expr (o: o.tag {c = "1";}) tag-list) false]
    [(expr (o: o.tag {a = [];}) tag-list) true]
    [(expr (o: o.tag {c = [];}) tag-list) false]
    [(expr (o: o.tag ({a = "1";} // {b = "9";})) tag-list) false]
    [(expr (o: o.tag {b = ["9" "2"];}) tag-list) true]
    [(expr (o: with o; !(tag {c = [];})) tag-list) true]
    [(expr (o: with o; !(tag {a = [];})) tag-list) false]
    [(expr (o: with o; (tag {a = "9";}) || (tag {b = "1";})) tag-list) true]
    [(expr (o: with o; (tag {a = "9";}) || (tag {c = [];})) tag-list) false]
  ];
}
