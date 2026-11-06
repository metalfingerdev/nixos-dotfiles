{ ... }:
{
  flake.modules.homeManager.luarocks = { pkgs, ... }: 
    let
      # Combines Lua 5.4 with the Luarocks management layer
      luaEnv = pkgs.lua5_4.withPackages (ps: with ps; [
        luarocks
      ]);
    in
    {
      home.packages = with pkgs; [
        luaEnv
        # Toolchain dependencies required to build native C rock extensions
        gcc
        gnumake
        pkg-config
      ];

      # Bind rock-installed binaries and paths to the local environment pathing
      home.sessionVariables = {
        LUA_PATH = "$HOME/.luarocks/share/lua/5.4/?.lua;$HOME/.luarocks/share/lua/5.4/?/init.lua;;";
        LUA_CPATH = "$HOME/.luarocks/lib/lua/5.4/?.so;;";
      };

      home.sessionPath = [
        "$HOME/.luarocks/bin"
      ];
    };
}
