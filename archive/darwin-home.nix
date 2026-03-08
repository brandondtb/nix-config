{
  pkgs,
  lib,
  secondaryTailnets,
  ...
}:

let
  tailnetScripts = import ../lib/tailnet-scripts.nix {
    inherit pkgs lib secondaryTailnets;
    socketDir = "/var/run";
    startService = name: "sudo launchctl kickstart system/org.nixos.tailscaled-${name}";
    stopService = name: "sudo launchctl kill SIGTERM system/org.nixos.tailscaled-${name}";
  };
in
lib.mkIf pkgs.stdenv.isDarwin {
  home.homeDirectory = lib.mkDefault /Users/brandon;

  home.packages = builtins.attrValues tailnetScripts;

  programs.ghostty = {
    enable = true;

    package = null;

    settings = {
      font-family = "AtkynsonMono Nerd Font Mono";
      font-size = 14;
      term = "xterm-256color";
    };
  };
}
