{ ... }:
{
  # omen's VS Code, on top of the shared feature (features/vscode); its Radeon wrapper is in radeon.nix.
  # Merged into the `omen` module.
  flake.modules.nixos.omen.home-manager.users.admin = { config, pkgs, ... }: {
    programs.vscode.profiles.default.extensions = [ pkgs.vscode-extensions.anthropic.claude-code ];
    # My settings, linked live to the config/vscode checkout so VS Code's own edits land there (and the
    # shared defaults are never seeded over it).
    xdg.configFile."Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.sessionVariables.NIXOS_FLAKE}/config/vscode/settings.json";
  };
}
