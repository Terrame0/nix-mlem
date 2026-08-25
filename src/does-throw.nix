{...}: rec {
  does-throw = value:
    !(builtins.tryEval (builtins.deepSeq value true)).success;
  tests = [
    [(does-throw (throw "ABC")) true]
    [(does-throw "ABC") false]
  ];
}
