{ lib, ... }:
{
  # A patch an update can outdate. It's applied only while every hunk still matches the file it edits
  # (what `patch` needs, without fuzz), so an update that moves that code builds the package unpatched
  # and warns, instead of failing the whole rebuild. One file per patch.
  flake.lib.optionalPatch = { name, patch, file }:
    let
      source = builtins.readFile file;
      hunks = lib.tail (lib.splitString "\n@@" (builtins.readFile patch));
      # a hunk's context and removed lines, i.e. the text it expects to find
      expected = hunk: lib.concatMapStringsSep "\n"
        (line: builtins.substring 1 (builtins.stringLength line) line)
        (lib.filter (line: lib.hasPrefix " " line || lib.hasPrefix "-" line) (lib.tail (lib.splitString "\n" hunk)));
      applies = hunks != [ ] && lib.all (hunk: lib.hasInfix (expected hunk) source) hunks;
    in
    {
      inherit applies;
      patches = lib.optional applies patch;
      warnings = lib.optional (!applies)
        "${name}: ${baseNameOf patch} no longer matches the updated source, so it's built without it. Remake the patch against the new code.";
    };
}
