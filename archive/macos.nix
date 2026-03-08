{
  config,
  pkgs,
  lib,
  secondaryTailnets,
  ...
}:

let
  postgresDataDir = "/var/lib/postgresql";
in
{
  nixpkgs.config = {
    allowUnfree = true;

    # Workaround for fish test failures on macOS
    # See: https://github.com/NixOS/nixpkgs/issues/461406
    packageOverrides = pkgs: {
      fish = pkgs.fish.overrideAttrs (oldAttrs: {
        doCheck = false;
      });
    };
  };

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.cleanup = "zap";

    taps = [
      "nikitabobko/tap"
    ];

    casks = [
      "1password"
      "appcleaner"
      "betterdisplay"
      "calibre"
      "claude"
      "discord"
      "firefox"
      "fujifilm-x-raw-studio"
      "ghostty"
      "google-chrome"
      "hhkb-studio"
      "ibkr"
      "keepingyouawake"
      "mullvad-vpn@beta"
      "obsidian"
      "slack"
      "tailscale-app"
      "trader-workstation"
      "zen-browser"
      "zoom"
    ];
  };

  nix.enable = false;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;
    dataDir = postgresDataDir;
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  # Create postgres data directory before activation
  system.activationScripts.preActivation.text = ''
    if [ ! -d "${postgresDataDir}" ]; then
      mkdir -p "${postgresDataDir}"
      chmod 700 "${postgresDataDir}"
      chown -R brandon:staff "${postgresDataDir}"
    fi
  '';

  # Add logging for debugging
  launchd.user.agents.postgresql.serviceConfig = {
    StandardErrorPath = "/tmp/postgres.error.log";
    StandardOutPath = "/tmp/postgres.out.log";
  };

  launchd.daemons = lib.mapAttrs' (
    name: cfg:
    lib.nameValuePair "tailscaled-${name}" {
      serviceConfig = {
        Label = "org.nixos.tailscaled-${name}";
        ProgramArguments = [
          "${pkgs.tailscale}/bin/tailscaled"
          "--tun=userspace-networking"
          "--state=/var/lib/tailscale-${name}/tailscaled.state"
          "--socket=/var/run/tailscale-${name}/tailscaled.sock"
          "--port=0"
          "--socks5-server=localhost:${toString cfg.socks5Port}"
        ];
        RunAtLoad = false;
      };
    }
  ) secondaryTailnets;

  system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: cfg: ''
      mkdir -p /var/lib/tailscale-${name}
      mkdir -p /var/run/tailscale-${name}
    '') secondaryTailnets
  );

  system.stateVersion = 6;
}
