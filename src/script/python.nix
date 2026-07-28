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
    deps ? [],
  }: let
    target = lib.pipe entrypoint [
      sundry.vfs.path.from-str
      (sundry.vfs.path.set.ext "")
      (sundry.str.join-with ".")
    ];
    missing-deps = lib.pipe deps [
      (lib.filter (dep: !(lib.hasAttr dep pkgs.python3Packages)))
      (map (dep: "'${dep}'"))
    ];
    dependencies =
      if missing-deps == []
      then lib.attrVals deps pkgs.python3Packages
      else throw "\npython script '${pname}' has unknown dependencies: ${sundry.str.join-with ", " missing-deps}";
    deps-str = "[${sundry.str.join-with "," (map (str: "\"${str}\"") deps)}]";
    project-config = sundry.vfs.file.from-text ["pyproject.toml"] ''
      [build-system]
      requires = ["hatchling"]
      build-backend = "hatchling.build"
      [project]
      name = "${pname}"
      version = "${version}"
      dependencies = ${deps-str}
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
      inherit pname version;
      pyproject = true;
      src = build-tree.drv;
      build-system = [pkgs.python3Packages.hatchling];
      inherit dependencies;
    };
  tests = [
    [
      (builtins.readFile (pkgs.runCommand "python-test" {
        nativeBuildInputs = [
          (python {
            pname = "hello";
            source = "${flake-root}/tests/python";
            deps = ["click"];
          })
        ];
      } "hello 'world' > $out"))
      "hello, world!\n"
    ]
    [
      (sundry.does-throw ((python {
        pname = "missing-dep";
        source = "${flake-root}/tests/python";
        deps = ["not-a-real-python-dependency"];
      }).outPath))
      true
    ]
  ];
}
