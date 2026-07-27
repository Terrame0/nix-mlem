{lib, ...}: {
  split = lib.splitString;
  join = lib.concatStrings;
  join-with = lib.concatStringsSep;
  len = lib.stringLength;
  pretty = lib.generators.toPretty {};
}
