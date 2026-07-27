nix eval --impure --raw --show-trace --expr '
  let
    nixpkgs = builtins.getFlake "nixpkgs";
    flake = builtins.getFlake (toString ./.);
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in
    pkgs.lib.generators.toPretty {} (flake.outputs.eval-tests { inherit pkgs; })
'
echo