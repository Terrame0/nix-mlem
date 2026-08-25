{
  sundry,
  lib,
  ...
}: rec {
  is-dir = path: node:
    !is-leaf path node # -- to avoid forcing evaluation of lazy leaf payloads
    && lib.all lib.id (lib.mapAttrsToList (name: value: lib.isAttrs value) node);
  is-leaf = _: node: let
    text = node.text or null;
    origin = node.origin or null;
  in
    lib.isString text
    || lib.isString origin
    || lib.isDerivation origin;
  is-leaf-node = path: node:
    if !lib.isAttrs node
    then throw "\nvfs directory node at '/${sundry.vfs.path.get.str path}' is not an attribute set"
    else if is-leaf path node
    then true
    else if is-dir path node
    then false
    else throw "\nvfs directory node at '/${sundry.vfs.path.get.str path}' is neither a leaf nor a directory";
  tests = [
    [(is-dir "..." {a = {};}) true]
    [(is-dir "..." {}) true]
    [(is-dir "..." {a = 10;}) false]
    [
      (is-dir "..." {
        origin = "...";
        expr = throw "expr was forced";
      })
      false
    ]
    [(is-leaf "..." {text = "...";}) true]
    [
      (is-leaf "..." {
        origin = "...";
        expr = throw "expr was forced";
      })
      true
    ]
    [(is-leaf "..." {expr = 10;}) false]
    [(is-leaf "..." {file = {text = "...";};}) false]
    [(is-leaf "..." {text = {};}) false]
    [(is-leaf-node "..." {text = "...";}) true]
    [
      (is-leaf-node "..." {
        origin = "...";
        expr = throw "expr was forced";
      })
      true
    ]
    [(is-leaf-node "..." {a = {};}) false]
    [(sundry.does-throw (is-leaf-node ["x" "y" "z"] {a = 10;})) true]
    [(sundry.does-throw (is-leaf-node ["x" "y" "z"] 10)) true]
  ];
}
