# Generates ts-<name>-up/down/status wrapper scripts for secondary tailnets.
{
  pkgs,
  lib,
  secondaryTailnets,
  socketDir,
  startService,
  stopService,
}:
builtins.listToAttrs (
  lib.concatLists (
    lib.mapAttrsToList (
      name: cfg:
      let
        socket = "${socketDir}/tailscale-${name}/tailscaled.sock";
      in
      [
        {
          name = "ts-${name}-up";
          value = pkgs.writeShellScriptBin "ts-${name}-up" ''
            echo "Connecting to ${name} (${cfg.tailnetName})..."
            ${startService name}
            sudo ${pkgs.tailscale}/bin/tailscale --socket=${socket} up
          '';
        }
        {
          name = "ts-${name}-down";
          value = pkgs.writeShellScriptBin "ts-${name}-down" ''
            echo "Disconnecting from ${name} (${cfg.tailnetName})..."
            sudo ${pkgs.tailscale}/bin/tailscale --socket=${socket} down
            ${stopService name}
          '';
        }
        {
          name = "ts-${name}-status";
          value = pkgs.writeShellScriptBin "ts-${name}-status" ''
            echo "Tailnet: ${name} (${cfg.tailnetName})"
            sudo ${pkgs.tailscale}/bin/tailscale --socket=${socket} status "$@"
          '';
        }
      ]
    ) secondaryTailnets
  )
)
