{
  lib,
  sundry,
  ...
}: let
  not-leaf = attrs:
    lib.isAttrs attrs
    && !(attrs ? check
      || attrs ? default
      || attrs == {});
  compare-until-leaf = sundry.attrs.compare-until not-leaf;
  collapse-until =
    lib.mapAttrsToListRecursiveCond (path: not-leaf);
  filter-map = fn: attrs:
    lib.pipe attrs [
      (collapse-until
        (path: attrs: let
          result = fn path attrs;
        in
          if !result.omit
          then
            lib.setAttrByPath
            path
            result.value
          else {}))
      lib.mergeAttrsList
    ];
  concat-path = strs: lib.concatStringsSep " -> " (map (str: "'${str}'") strs);
  format = lib.generators.toPretty {multiline = false;};
in rec {
  validate = template-in: attrs: let
    template = lib.mapAttrsRecursiveCond not-leaf (path: value: let
      structure-msg = ''
        'check' - an attribute value validation function
        'desc' - a description of a valid value
        'default' - a default attribute value
        'nullable' - a flag that indicates whether the value can be null
      '';
    in
      if !(lib.isAttrs value)
      then
        throw ''
          an attribute template must be an attribute set with the following structure:
          ${structure-msg}
        ''
      else if
        (compare-until-leaf value {
          check = null;
          desc = null;
          default = null;
          nullable = null;
        }).extra
        == {}
      then value
      else
        throw ''
          an attribute template can only have the following attributes:
          ${structure-msg}
        '')
    template-in;

    compared-with-template = compare-until-leaf attrs template;

    defaults =
      filter-map (
        path: value: {
          value = [value.default value];
          omit = !(value ? default);
        }
      )
      compared-with-template.missing;

    matched-with-defaults =
      sundry.attrs.merge.recursive.no-collision
      [compared-with-template.matched defaults];

    missing =
      lib.pipe
      (compare-until-leaf defaults compared-with-template.missing).missing
      [
        (collapse-until
          (path: value: "  ${concat-path path} | ${value.desc or "..."}"))
        (lib.concatStringsSep "\n")
      ];

    extra =
      lib.pipe
      compared-with-template.extra
      [
        (collapse-until
          (path: value: "  ${concat-path path} = ${format value}"))
        (lib.concatStringsSep "\n")
      ];

    did-not-pass = lib.pipe matched-with-defaults [
      (collapse-until (
        path: pair: let
          decomposed = sundry.list.zip-to-attrs ["value" "spec"] pair;
          inherit (decomposed) value spec;
          passed =
            if spec.nullable or false && value == null
            then true
            else if !(spec ? check)
            then true
            else if !(spec ? desc)
            then throw "attribute spec that has a 'check' attribute must also have a 'desc' attribute"
            else let test-result = spec.check value; in assert builtins.isBool test-result; test-result;
        in
          if passed
          then []
          else ["  ${concat-path path} = ${format value} | ${spec.desc}"]
      ))
      lib.concatLists
      (lib.concatStringsSep "\n")
    ];
    values =
      lib.mapAttrsRecursive
      (path: pair: sundry.list.at 0 pair)
      matched-with-defaults;
  in
    lib.foldl
    sundry.check-success
    values [
      {
        success = did-not-pass == "";
        error-msg = "incorrect attribute values:\n${did-not-pass}";
      }
      {
        success = extra == "";
        error-msg = "got extra attributes:\n${extra}";
      }
      {
        success = missing == "";
        error-msg = "missing attributes:\n${missing}";
      }
    ];

  tests = [
    [
      (
        validate
        {
          A = {
            check = value: lib.mod value 1 == 0;
            desc = "must be odd";
          };
          B = {
            default = null;
            nullable = true;
          };
          C = {
            D = {
              default = 3;
              check = value: lib.mod value 3 == 0;
              desc = "must be divisible by 3";
            };
          };
        }
        {
          A = 1;
          B = 2;
        }
      )
      {
        A = 1;
        B = 2;
        C = {
          D = 3;
        };
      }
    ]
    [
      (sundry.does-throw (
        validate
        {
          A = {};
          B = {};
        }
        {A = 1;}
      ))
      true
    ]
    [
      (sundry.does-throw (
        validate
        {
          A = {
            default = 2;
            check = value: lib.mod value 2 == 0;
            desc = "must be even";
          };
        }
        {A = 1;}
      ))
      true
    ]
    [
      (sundry.does-throw (
        validate
        {
          A = {};
        }
        {
          A = 1;
          B = 2;
        }
      ))
      true
    ]
  ];
}
