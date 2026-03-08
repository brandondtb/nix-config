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
  networking.networkmanager = {
    enable = true;
    # NM pushes DHCP DNS to resolved as per-link DNS regardless of dns/systemd-resolved
    # settings (NM 1.56 bug). Clear it after each connection comes up.
    dispatcherScripts = [
      {
        source = pkgs.writeText "clear-link-dns" ''
          if [ "$2" = "up" ] && [ "$1" != "tailscale0" ]; then
            ${pkgs.systemd}/bin/resolvectl dns "$1" ""
            ${pkgs.systemd}/bin/resolvectl default-route "$1" false
          fi
        '';
        type = "basic";
      }
    ];
  };

  # TODO: Re-enable NextDNS once ISP routing issues resolve
  # services.nextdns = {
  #   enable = true;
  #   arguments = [
  #     "-profile" "7d61b4"
  #     "-listen" "127.0.0.2:53"
  #     "-cache-size" "10MB"
  #   ];
  # };

  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "1.0.0.1#cloudflare-dns.com"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "yes";
      Domains = [ "~." ];
    };
  };

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
    extraSetFlags = [ "--accept-dns=false" ];
  };

  services.postgresql = {
    enable = true;
    authentication = lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  systemd.services = lib.mkMerge [
    (lib.mapAttrs' (
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
    ) secondaryTailnets)

    # Re-apply MagicDNS split DNS on tailscale0 whenever Tailscale resets it
    {
      tailscale-dns-split = {
        description = "Maintain MagicDNS split DNS on tailscale0";
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
          iproute2
          systemd
          gnugrep
        ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 5;
        };
        script = ''
          apply_dns() {
            if ip link show tailscale0 &>/dev/null; then
              resolvectl dns tailscale0 100.100.100.100
              resolvectl domain tailscale0 "~ts.net"
              resolvectl default-route tailscale0 false
              resolvectl dnsovertls tailscale0 false
            fi
          }

          sleep 3
          apply_dns

          journalctl -u tailscaled -f -n0 --grep="dns" | while read -r line; do
            sleep 1
            apply_dns
          done
        '';
      };
    }
  ];

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
      "networkmanager"
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.nix-ld.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "brandon" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    cachix

    dmidecode
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
