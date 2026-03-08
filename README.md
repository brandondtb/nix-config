# nix-config

NixOS/nix-darwin flake configuration managing multiple machines.

## Machines

- **dreadnought** - x86_64 NixOS desktop with NVIDIA GPU
- **relm** - x86_64 NixOS
- **ultros** - aarch64 macOS with nix-darwin and Homebrew integration

## Setup

### Secure Boot (Lanzaboote)

All NixOS machines use [Lanzaboote](https://github.com/nix-community/lanzaboote) for Secure Boot. Before building for the first time on a new machine, you must generate signing keys:

```bash
nix shell nixpkgs#sbctl
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
```

Keys are stored in `/var/lib/sbctl`. The `--microsoft` flag includes Microsoft's keys for third-party firmware/driver compatibility.

## Usage

### Building and Switching Configurations

For Linux (NixOS):
```bash
sudo nixos-rebuild switch --flake .

# Or using nh
nh os switch
```

For macOS (nix-darwin):
```bash
darwin-rebuild switch --flake .

# Or using nh
nh darwin switch
```

### Updating Dependencies

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs
```

### Development

```bash
# Format nix files
nixfmt .

# Check flake
nix flake check

# Show flake info
nix flake show
```
