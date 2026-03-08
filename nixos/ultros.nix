{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hardware-ultros.nix ];

  networking.hostName = "ultros";

  # Systemd initrd caches the LUKS passphrase so both root and swap are
  # unlocked with a single password prompt.
  boot.initrd.systemd.enable = true;

  # Resume from encrypted swap for hibernate
  boot.resumeDevice = "/dev/mapper/luks-33a2c874-f370-46ab-a252-5dca64198209";

  hardware.enableAllFirmware = true;

  # Intel Arc / Xe integrated graphics (Arrow Lake-U)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  # Laptop power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Better laptop power savings
  powerManagement.enable = true;

  # Suspend on lid close
  services.logind.settings.Login.HandleLidSwitch = "suspend";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "suspend";

  # Fingerprint reader
  services.fprintd.enable = true;

  # Accelerometer / auto-rotate for tablet mode
  hardware.sensor.iio.enable = true;

  # On-screen keyboard for tablet mode (select in System Settings > Input Devices > Virtual Keyboard)
  environment.systemPackages = with pkgs; [
    maliit-keyboard
    maliit-framework
  ];

  hardware.bluetooth.powerOnBoot = true;
}
