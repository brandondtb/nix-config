{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hardware-dreadnought.nix ];
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];

  # Pin to 6.18 until NVIDIA open driver supports 6.19
  boot.kernelPackages = pkgs.lib.mkForce pkgs.linuxPackages_6_18;

  # Enable systemd in initrd for TPM2 unlock
  boot.initrd.systemd.enable = true;

  # TPM2 auto-unlock for LUKS partitions
  boot.initrd.luks.devices."luks-b1b26a55-fa2f-404c-9a4e-1b61c4418c81".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];
  boot.initrd.luks.devices."luks-02408d0b-15ca-4bcb-ad96-0c3bfe1007c9".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];

  boot.blacklistedKernelModules = [ "k10temp" ];

  boot.kernelModules = [
    "zenpower"
  ];

  boot.kernelParams = [
    "amd_pstate=active"
    "nvidia-drm.fbdev=1"
  ];

  # Disable onboard Bluetooth (Realtek 0bda:0852) in favor of USB dongle
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="0852", ATTR{authorized}="0"
  '';

  hardware.enableAllFirmware = true;

  hardware.amdgpu.initrd.enable = false;

  services.tailscale.extraUpFlags = [
    "--advertise-routes=192.168.68.0/22"
  ];

  services.logind.settings.Login.RuntimeDirectorySize = "100G";

  networking.hostName = "dreadnought";
  networking.firewall.allowedTCPPorts = [
    21000
    21010
    19450 # Calibre content server
  ];

  # Libvirt / Virtual Machine Manager
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulation
    };
  };
  programs.virt-manager.enable = true;

  # TODO: Remove after nixpkgs-unstable includes NixOS/nixpkgs#496839
  systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart =
    let
      script = pkgs.writeShellScript "virt-secret-init-encryption" ''
        umask 0077
        dd if=/dev/random status=none bs=32 count=1 \
          | ${pkgs.systemd}/bin/systemd-creds encrypt \
              --name=secrets-encryption-key - \
              /var/lib/libvirt/secrets/secrets-encryption-key
      '';
    in
    # Empty string clears the original ExecStart before setting the new one
    lib.mkForce [
      ""
      script
    ];

  services.logind.settings.Login.IdleAction = "ignore";

  # SDDM on X11 to support DPMS screen blanking at the greeter
  # Wayland SDDM lacks idle DPMS support (KDE bug #484015)
  services.displayManager.sddm.wayland.enable = false;
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xset}/bin/xset dpms 60 60 60
    ${pkgs.xset}/bin/xset s 60
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  sops.defaultSopsFile = ../secrets/dreadnought.yaml;
  sops.secrets.slskd_env = {
    owner = "brandon";
  };

  # Soulseek (slskd)
  services.slskd = {
    enable = true;
    domain = null;
    openFirewall = true;
    user = "brandon";
    group = "users";
    environmentFile = config.sops.secrets.slskd_env.path;
    settings = {
      directories.downloads = "/home/brandon/Music/slskd/downloads";
      directories.incomplete = "/home/brandon/Music/slskd/incomplete";
      shares.directories = [ ];
      soulseek.listen_port = 50300;
      web.port = 5030;
    };
  };

  # Allow slskd to write to home directory for downloads
  systemd.services.slskd.serviceConfig.ProtectHome = lib.mkForce false;

  # Allow navidrome to read music library in home directory
  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce false;

  # Navidrome music streaming server
  services.navidrome = {
    enable = true;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      MusicFolder = "/home/brandon/Music/library";
    };
  };

  # Expose Navidrome web UI on the tailnet via tailscale serve
  systemd.services.tailscale-serve-navidrome = {
    description = "Expose Navidrome via Tailscale Serve";
    after = [
      "tailscaled.service"
      "navidrome.service"
      "network-online.target"
      "tailscale-serve-slskd.service"
    ];
    wants = [
      "tailscaled.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    script = ''
      until tailscale status --peers=false >/dev/null 2>&1; do
        sleep 1
      done
      tailscale serve --bg --https 8443 http://127.0.0.1:4533
    '';
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https 8443 off";
    };
  };

  # Expose slskd web UI on the tailnet via tailscale serve
  systemd.services.tailscale-serve-slskd = {
    description = "Expose slskd via Tailscale Serve";
    after = [
      "tailscaled.service"
      "slskd.service"
      "network-online.target"
    ];
    wants = [
      "tailscaled.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    script = ''
      until tailscale status --peers=false >/dev/null 2>&1; do
        sleep 1
      done
      tailscale serve --bg 5030
    '';
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve off";
    };
  };
}
