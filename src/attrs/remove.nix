{lib, ...}: rec {
  remove = lib.flip removeAttrs;
  tests = [
    [
      (remove ["B" "C"] {
        A = 1;
        B = 2;
        C = 3;
      })
      {A = 1;}
    ]
  ];
}
