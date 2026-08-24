{lib, ...}: rec {
  not = predicate: value: !(predicate value);
  tests = [
    [((not lib.isAttrs) {A = 1;}) false]
    [((not lib.isInt) 0.5) true]
  ];
}
