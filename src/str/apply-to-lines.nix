{sundry, ...}: rec {
  apply-to-lines = fn: str:
    sundry.str.join-with "\n" (map fn (sundry.str.split "\n" str));
  tests = [
    [
      (apply-to-lines
        (line: "${line}-modified")
        ''
          A
          B
          C'')
      ''
        A-modified
        B-modified
        C-modified''
    ]
    [(apply-to-lines (line: "${line}-modified") "A") "A-modified"]
  ];
}
