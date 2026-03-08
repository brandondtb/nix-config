# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Building and Switching Configurations

For Linux (dreadnought/relm/ultros - NixOS):
```bash
# Build and switch to new configuration
sudo nixos-rebuild switch --flake .

# Using nh
nh os switch
```

### Updating Dependencies
```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs
```

### Development Commands
```bash
# Format nix files
nixfmt .

# Check flake
nix flake check

# Show flake info
nix flake show
```

## Repository Architecture

This is a NixOS flake configuration managing personal desktop machines. Server infrastructure (zoneseek/OVH) lives in the separate `radiation-io/infra` repo, which imports `home-manager/base.nix` from this repo as a flake input.

### System Configurations
- **dreadnought** - x86_64 NixOS desktop with NVIDIA GPU
- **relm** - x86_64 NixOS
- **ultros** - x86_64 NixOS laptop (ThinkPad X1 2-in-1 Gen 10, Intel Arrow Lake-U)

### Key Components
1. **flake.nix** - Main entry point defining:
   - nixosConfigurations for Linux desktop systems
   - Input dependencies (nixpkgs, home-manager, lanzaboote, sops-nix, nix-flatpak)

2. **nixos/common.nix** - Shared NixOS desktop configuration:
   - System services (KDE Plasma 6, PipeWire, printing)
   - Core programs (1Password, Steam, nh)
   - User account setup

3. **nixos/*.nix** - Host-specific NixOS configurations:
   - Hardware configuration
   - Host-specific kernel modules and drivers
   - Network configuration

4. **home-manager/base.nix** - Shared home-manager config for all machines (desktops and servers):
   - Development tools (git, neovim, tmux, direnv)
   - Language environments (Node.js, Python)
   - Cloud tools (AWS, GCP, Kubernetes, Terraform)
   - Terminal configuration (zsh)
   - Claude Code and Opencode config

5. **home-manager/desktop.nix** - Desktop-only home-manager config:
   - Fonts, GUI apps (keepassxc, feishin, cider-2)
   - Syncthing, beets, IBKR packages
   - Secondary tailnet wrapper scripts

6. **home-manager/home.nix** - Thin wrapper importing base.nix + desktop.nix for personal machines

7. **tailscale-secondary.nix** - Shared definition of secondary Tailscale tailnets:
   - Each entry generates a systemd service, wrapper scripts, and SSH proxy config
   - Adding a new tailnet is a one-liner in this file

### Related Repos
- **radiation-io/infra** (`~/src/radiation/infra`) - Server infrastructure (zoneseek OVH dedicated server). Imports `home-manager/base.nix` from this repo via flake input.

### Configuration Patterns
- All current machines run NixOS with Home Manager as a NixOS module
- Legacy macOS config lives in `archive/`
- Flake inputs are pinned and shared across configurations using `follows`
- Server configs live in `radiation-io/infra` to allow multi-user access

## Secondary Tailscale Tailnets

Secondary tailnets run alongside the primary Tailscale instance using userspace networking and a SOCKS5 proxy. Defined in `tailscale-secondary.nix`.

### Adding a New Tailnet

Add an entry to `tailscale-secondary.nix`:

```nix
{
  vody = {
    tailnetName = "tailde28d5.ts.net";
    socks5Port = 1055;
    sshMatch = "*.tailde28d5.ts.net";
  };
  new-tailnet = {
    tailnetName = "tailXXXXXX.ts.net";
    socks5Port = 1056;
    sshMatch = "*.tailXXXXXX.ts.net";
  };
}
```

This auto-generates:
- A `systemd.services.tailscaled-<name>` unit (does not auto-start)
- Wrapper scripts: `ts-<name>-up`, `ts-<name>-down`, `ts-<name>-status`
- SSH matchBlocks routing `sshMatch` hosts through the SOCKS5 proxy

### Usage

```bash
ts-vody-up                          # Start daemon and authenticate
ts-vody-status                      # Show peers and tailnet info
ssh host.tailde28d5.ts.net          # Routed through SOCKS5 automatically
ts-vody-down                        # Disconnect and stop daemon
```

### Browser SOCKS5 Proxy

To access web services on a secondary tailnet from your browser, configure a SOCKS5 proxy:

**Firefox:**
1. Settings > Network Settings > Settings...
2. Select "Manual proxy configuration"
3. SOCKS Host: `localhost`, Port: `1055` (or the tailnet's `socks5Port`)
4. Select "SOCKS v5"
5. Check "Proxy DNS when using SOCKS v5"

**Chromium/Chrome (CLI flag):**
```bash
google-chrome-stable --proxy-server="socks5://localhost:1055"
```

**FoxyProxy (Firefox/Chrome extension):**
1. Install FoxyProxy Standard
2. Add a new proxy: SOCKS5, `localhost`, port `1055`
3. Add URL patterns for `*.tailde28d5.ts.net` to route only tailnet traffic through the proxy
4. This avoids proxying all browser traffic

**Tip:** FoxyProxy with URL patterns is recommended -- it lets you selectively proxy only tailnet hostnames while keeping normal browsing direct.
