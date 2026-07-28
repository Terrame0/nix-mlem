{
  sundry,
  lib,
  pkgs,
  flake-root,
  ...
}: rec {
  python = {
    pname,
    source,
    version ? "1.0.0",
    entrypoint ? "main.py",
    entrypoint-fn ? "main",
    deps ? py: [],
  }: let
    target = lib.pipe entrypoint [
      sundry.vfs.path.from-str
      (sundry.vfs.path.set.ext "")
      (sundry.str.join-with ".")
    ];
    dependencies = deps pkgs.python3Packages;
    project-config = sundry.vfs.file.from-text ["pyproject.toml"] ''
      [build-system]
      requires = ["hatchling"]
      build-backend = "hatchling.build"
      [project]
      name = "${pname}"
      version = "${version}"
      [project.scripts]
      ${pname} = "${target}:${entrypoint-fn}"
      [tool.hatch.build.targets.wheel]
      only-include = ["."]
    '';
    build-tree = lib.pipe source [
      sundry.vfs.dir.from-src
      (dir: sundry.attrs.merge.recursive.no-collision [dir project-config])
      (sundry.vfs.dir.materialize pname)
    ];
  in
    pkgs.python3Packages.buildPythonApplication {
      inherit dependencies pname version;
      pyproject = true;
      src = build-tree.drv;
      build-system = [pkgs.python3Packages.hatchling];
    };
  tests = [
    [
      (builtins.readFile (pkgs.runCommand "python-test" {
        nativeBuildInputs = [
          (python {
            pname = "hello";
            source = "${flake-root}/tests/python";
            deps = py: [py.click];
          })
        ];
      } "hello 'world' > $out"))
      "hello, world!\n"
    ]
  ];
}
