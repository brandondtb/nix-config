{
  config,
  pkgs,
  lib,
  secondaryTailnets,
  ...
}:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = "auto";
    cores = 0;
  };

  services.openssh.enable = true;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Lanzaboote replaces systemd-boot for Secure Boot support
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;

  systemd.network.networks."40-wired" = {
    matchConfig = {
      Type = "ether";
      Name = "!virbr* veth* docker* br-*";
    };
    networkConfig.DHCP = "yes";
    dhcpV4Config.RouteMetric = 100;
  };
  systemd.network.networks."40-wireless" = {
    matchConfig.Type = "wlan";
    networkConfig.DHCP = "yes";
    dhcpV4Config.RouteMetric = 600;
  };

  # NextDNS is pushed via Tailscale's --accept-dns (tailnet DNS config).
  # If ISP routing issues return, set --accept-dns=false and configure
  # Cloudflare nameservers + manual split DNS for tailscale0 instead.
  services.resolved.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.fwupd.enable = true;
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  hardware.bluetooth.enable = true;

  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
    extraSetFlags = [ "--accept-dns=true" ];
  };

  services.postgresql = {
    enable = true;
    authentication = lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  systemd.services = lib.mapAttrs' (
    name: cfg:
    lib.nameValuePair "tailscaled-${name}" {
      description = "Tailscale daemon for ${name} tailnet";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --state=/var/lib/tailscale-${name}/tailscaled.state --socket=/run/tailscale-${name}/tailscaled.sock --port=0 --socks5-server=localhost:${toString cfg.socks5Port}";
        RuntimeDirectory = "tailscale-${name}";
        StateDirectory = "tailscale-${name}";
        Restart = "on-failure";
      };
      wantedBy = [ ]; # Don't auto-start
    }
  ) secondaryTailnets;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

  services.fstrim.enable = true;

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "app.zen_browser.zen"
    "com.discordapp.Discord"
    "com.google.Chrome"
    "com.slack.Slack"
    "md.obsidian.Obsidian"
    "org.telegram.desktop"
    "com.calibre_ebook.calibre"
    "us.zoom.Zoom"
  ];

  users.users.brandon = {
    isNormalUser = true;
    description = "Brandon Beveridge";
    extraGroups = [
      "libvirtd"
      "network"
      "wheel"
    ];
    packages = with pkgs; [
      firefox
      powerstat
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/brandon/nix-config";
  };

  # programs.partition-manager.enable = true; # KDE

  programs.kdeconnect.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraPackages = [ pkgs.hidapi ];
  };

  programs.nix-ld.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "brandon" ];
  };

  nixpkgs.config.allowUnfree = true;

  # Workaround: cli-helpers 2.10.0 tests fail with current Pygments (NixOS/nixpkgs#513102)
  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = pyFinal: pyPrev: {
          cli-helpers = pyPrev.cli-helpers.overridePythonAttrs { doCheck = false; };
        };
      };
      python3Packages = final.python3.pkgs;
    })
  ];

  environment.systemPackages = with pkgs; [
    (makeDesktopItem {
      name = "steam-pipewire";
      desktopName = "Steam (PipeWire)";
      exec = "steam -pipewire %U";
      icon = "steam";
      categories = [ "Game" ];
      mimeTypes = [ "x-scheme-handler/steam" ];
    })
    cachix

    dmidecode
    impala
    exfatprogs
    fastfetch
    mesa-demos
    lshw
    pciutils
    powertop
    psmisc
    sbctl
    vim
    unzip
    wl-clipboard

    podman-compose
  ];

  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  system.stateVersion = "25.11";

}
