{sundry, ...}: rec {
  check-success = value: attrs:
    if !attrs ? success
    then throw "success validation attrset must have the 'success' attribute"
    else if !attrs ? error-msg
    then throw "success validation attrset must have the 'error-msg' attribute"
    else if attrs.success
    then value
    else throw "\n${attrs.error-msg}";

  tests = [
    [
      (check-success "A" {
        success = true;
        error-msg = "B";
      })
      "A"
    ]
    [
      (sundry.does-throw (check-success "A" {
        success = false;
        error-msg = "B";
      }))
      true
    ]
    [(sundry.does-throw (check-success "A" {error-msg = "B";})) true]
    [(sundry.does-throw (check-success "A" {success = true;})) true]
  ];
}
