{
  lib,
  sundry,
  ...
}: let
  is-spec = value:
    lib.isAttrs value
    && (
      value
      == {}
      || value ? check
      || value ? default
    );
  compare-until-spec = sundry.attrs.compare-until is-spec;
  collapse-until-spec = sundry.attrs.collapse-until (_: is-spec);
  format-path = strs: sundry.str.join-with "." (map (str: "'${str}'") strs);
  format-value = lib.generators.toPretty {multiline = false;};
in rec {
  validate = template': attrs: let
    template =
      sundry.attrs.walk-until
      (_: is-spec)
      (_: value: let
        spec-structure-msg = ''
          'check' - an attribute value validation function
          'desc' - a description of a valid value
          'default' - a function from the final result attribute set to a default attribute value
          'nullable' - a flag that indicates whether the value can be null
        '';
      in
        if !(lib.isAttrs value)
        then
          throw ''
            an attribute set template must be an attribute set with the following structure:
            ${spec-structure-msg}
          ''
        else if
          (sundry.attrs.compare value {
            check = null;
            desc = null;
            default = null;
            nullable = null;
          }).extra
          == {}
        then value
        else
          throw ''
            an attribute set template can only have the following attributes:
            ${spec-structure-msg}
          '')
      template';

    comparison = compare-until-spec attrs template;

    default-pairs = lib.pipe comparison.missing [
      (collapse-until-spec
        (path: spec:
          if spec ? default
          then lib.setAttrByPath path [(spec.default result) spec]
          else {}))
      sundry.attrs.merge.recursive.no-collision
    ];

    value-spec-pairs =
      sundry.attrs.merge.recursive.no-collision
      [comparison.matched default-pairs];

    missing-msg = lib.pipe comparison.missing [
      (collapse-until-spec
        (path: spec:
          lib.optional
          (!(spec ? default))
          "  ${format-path path} | ${spec.desc or "..."}"))
      lib.concatLists
      (sundry.str.join-with "\n")
    ];

    extra-msg =
      lib.pipe
      comparison.extra
      [
        (collapse-until-spec
          (path: value: "  ${format-path path} = ${format-value value}"))
        (sundry.str.join-with "\n")
      ];

    check-failures-msg = lib.pipe value-spec-pairs [
      (collapse-until-spec (
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
          else ["  ${format-path path} = ${format-value value} | ${spec.desc}"]
      ))
      lib.concatLists
      (sundry.str.join-with "\n")
    ];
    result =
      sundry.attrs.walk
      (_: pair: sundry.list.at 0 pair)
      value-spec-pairs;
  in
    lib.foldl
    sundry.check-success
    result [
      {
        success = check-failures-msg == "";
        error-msg = "incorrect attribute values:\n${check-failures-msg}";
      }
      {
        success = extra-msg == "";
        error-msg = "got extra attributes:\n${extra-msg}";
      }
      {
        success = missing-msg == "";
        error-msg = "missing attributes:\n${missing-msg}";
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
            default = _: null;
            nullable = true;
          };
          C = {
            D = {
              default = self: self.A + self.B;
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
      (
        validate
        {
          A = {
            default = self: self.B + 1;
          };
          B = {
            default = self: self.C + 1;
          };
          C = {};
        }
        {C = 1;}
      )
      {
        A = 3;
        B = 2;
        C = 1;
      }
    ]
    [
      (
        validate
        {
          A = {
            B = {
              default = _: 1;
            };
            C = {
              default = _: 2;
            };
          };
        }
        {}
      )
      {
        A = {
          B = 1;
          C = 2;
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
            default = _: 2;
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
    [
      (sundry.does-throw (
        validate
        {
          A = {
            check = lib.isInt;
            desc = "must be an integer";
            unexpected = true;
          };
        }
        {A = 1;}
      ))
      true
    ]
  ];
}
