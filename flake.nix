{
  description = "a nixos utility library";
  inputs = {};
  outputs = {self, ...}: let
    module-args = args': let
      args =
        args'
        // {
          inherit (args'.pkgs) lib;
          flake-root = self.outPath;
        };
    in
      args;
  in rec {
    mk-lib = {pkgs}:
      pkgs.lib.fix (self:
        import ./core/mk-lib.nix (module-args {
          inherit pkgs;
          sundry = self;
        }));
    eval-tests = args @ {pkgs}:
      import ./core/eval-tests.nix (module-args {
        inherit pkgs;
        sundry = mk-lib args;
      });
  };
}
