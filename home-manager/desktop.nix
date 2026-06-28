# Desktop-only home-manager configuration.
# Fonts, GUI apps, syncthing, beets, IBKR, etc.
# Imported by home.nix for personal desktop machines only.
{
  pkgs,
  lib,
  self,
  secondaryTailnets,
  ...
}:

let
  tailnetScripts = import ../lib/tailnet-scripts.nix {
    inherit pkgs lib secondaryTailnets;
    socketDir = "/run";
    startService = name: "sudo systemctl start tailscaled-${name}";
    stopService = name: "sudo systemctl stop tailscaled-${name}";
  };
in
lib.mkIf pkgs.stdenv.isLinux {
  home.packages =
    with pkgs;
    [
      # Fonts
      nerd-fonts.atkynson-mono
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono

      # GUI apps
      cider-2
      dbeaver-bin
      easyeffects
      feishin
      gimp
      imagemagick
      kdePackages.kdenlive
      krita
      rimsort
      steamcmd

      # IBKR
      self.packages.${pkgs.stdenv.hostPlatform.system}.tws
      self.packages.${pkgs.stdenv.hostPlatform.system}.tws-install
      self.packages.${pkgs.stdenv.hostPlatform.system}.ibkr-desktop
      self.packages.${pkgs.stdenv.hostPlatform.system}.ibkr-desktop-install
    ]
    ++ builtins.attrValues tailnetScripts;

  fonts.fontconfig.enable = true;

  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    settings.options = {
      globalAnnounceEnabled = false;
      localAnnounceEnabled = false;
      relaysEnabled = false;
      urAcceptedURL = -1;
    };
    settings.folders."Sync" = {
      path = "~/Sync";
      versioning = {
        type = "staggered";
        params = {
          cleanInterval = "3600";
          maxAge = "2592000"; # 30 days
        };
      };
    };
    settings.folders."Obsidian" = {
      path = "~/Obsidian";
      versioning = {
        type = "staggered";
        params = {
          cleanInterval = "3600";
          maxAge = "2592000"; # 30 days
        };
      };
    };
  };

  programs.beets = {
    enable = true;
    settings = {
      directory = "~/Music/library";
      library = "~/Music/library/beets.db";
      import = {
        move = true;
      };
      paths = {
        default = "%the{$albumartist}/$album/$track $title";
        singleton = "%the{$artist}/Singles/$title";
        comp = "Compilations/$album/$track $title";
      };
      plugins = "chroma fetchart the";
    };
  };
}
