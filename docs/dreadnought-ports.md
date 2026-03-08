# Dreadnought Exposed Ports

## Firewall-open ports (externally reachable)

| Port | Protocol | Service | Source |
|------|----------|---------|--------|
| 22 | TCP | OpenSSH | `services.openssh.enable` (common.nix) |
| 5353 | UDP | Avahi/mDNS | `services.avahi.openFirewall` (common.nix) |
| 21000 | TCP | LocalSend | `networking.firewall.allowedTCPPorts` (dreadnought.nix) |
| 21010 | TCP | LocalSend | `networking.firewall.allowedTCPPorts` (dreadnought.nix) |
| 19450 | TCP | Calibre content server | `networking.firewall.allowedTCPPorts` (dreadnought.nix) |
| 50300 | TCP | Soulseek P2P | `services.slskd.openFirewall` (dreadnought.nix) |
| 5030 | TCP | slskd web UI | `services.slskd.openFirewall` (dreadnought.nix) |
| 27036 | UDP | Steam Remote Play | `programs.steam.remotePlay.openFirewall` (common.nix) |
| 27031-27036 | TCP | Steam Remote Play | `programs.steam.remotePlay.openFirewall` (common.nix) |
| 27015 | TCP/UDP | Steam Dedicated Server | `programs.steam.dedicatedServer.openFirewall` (common.nix) |
| 27040 | TCP | Steam Local Transfer | `programs.steam.localNetworkGameTransfers.openFirewall` (common.nix) |

## Trusted interfaces (all traffic allowed)

| Interface | Service | Source |
|-----------|---------|--------|
| tailscale0 | Tailscale | `networking.firewall.trustedInterfaces` (common.nix) |

## Localhost-only services

| Port | Protocol | Service | Source |
|------|----------|---------|--------|
| 1055 | TCP | SOCKS5 proxy (vody tailnet) | `tailscale-secondary.nix` |
| 4533 | TCP | Navidrome | `services.navidrome` (dreadnought.nix) |
| 5432 | TCP | PostgreSQL | `services.postgresql` (common.nix) |
