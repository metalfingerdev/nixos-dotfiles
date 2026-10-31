{ ... }:
{
  flake.modules.nixos.webdev = { pkgs, ... }: {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdevnv.cc.cc
      openssl
      curl
      icu
    ];
   };

  flake.modules.homeManager.webdev = { pkgs, ... }: {
    home.packages = with pkgs; [
      # Runtimes and package managers
      nodejs
      pnpm
      bun

      # Language servers and tooling
      typescript
      typescript-language-server
      vscode-langservers-extracted # html, css, json, eslint
      svelte-language-server
      prettier
    ];

    # Global installs (`pnpm add -g`, `npm i -g`) go to $HOME instead of the read-only store
    home.sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    home.sessionPath = [
      "$HOME/.local/share/pnpm"
      "$HOME/.npm-global/bin"
    ];
  };
}
