{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ]; # enables flake.modules.<class>.<name>
  systems = [ "x86_64-linux" ];
}