{ config, pkgs, ... }:

{
  imports = [ ./hardware-relm.nix ];
  boot.initrd.luks.devices."luks-df9bdb8f-c069-4e23-8601-b7b76370e5e3".device =
    "/dev/disk/by-uuid/df9bdb8f-c069-4e23-8601-b7b76370e5e3";

  networking.hostName = "relm";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      vpl-gpu-rt
    ];
  };

}
