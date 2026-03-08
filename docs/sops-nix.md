# sops-nix Secrets Management

## Overview

Secrets are encrypted in the repo using [sops-nix](https://github.com/Mic92/sops-nix) with age encryption. Each machine decrypts secrets at activation time using an age key derived from its SSH host key. An admin age key (stored locally, never committed) can decrypt all secrets for editing.

## Architecture

- **`.sops.yaml`** — defines which age keys can encrypt/decrypt which secret files
- **`secrets/<hostname>.yaml`** — per-machine encrypted secret files
- **`~/.config/sops/age/keys.txt`** — admin private key (on your workstation, never committed)
- **`/etc/ssh/ssh_host_ed25519_key`** — machine private key (used by sops-nix at activation)

## Adding a New Machine

### 1. Ensure openssh is enabled

The machine needs SSH host keys. This is configured in `nixos/common.nix`:

```nix
services.openssh.enable = true;
```

If the machine is fresh, rebuild first so host keys are generated.

### 2. Derive the machine's age public key

```bash
sudo cat /etc/ssh/ssh_host_ed25519_key.pub | nix shell nixpkgs#ssh-to-age -c ssh-to-age
```

### 3. Add the key to `.sops.yaml`

```yaml
keys:
  - &admin age18evrtkw2u8aepymjed5wtxmddmajh7ltcpq4kk7wwrf4u6qtnv2surywn6
  - &dreadnought age1kv92a5l2xckkd7s89z75dd3096rtea3gddsfk9x6cwgdq6fuhcts37nyyt
  - &new-machine age1...
creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age:
          - *admin
          - *dreadnought
          - *new-machine
```

### 4. Re-encrypt existing secrets with the new key

After adding a new key to `.sops.yaml`, update all existing secret files so the new machine can decrypt them:

```bash
nix shell nixpkgs#sops -c sops updatekeys secrets/dreadnought.yaml
```

### 5. Create a secrets file for the new machine

```bash
nix shell nixpkgs#sops -c sops secrets/new-machine.yaml
```

### 6. Declare secrets in the machine's NixOS config

```nix
sops.defaultSopsFile = ../secrets/new-machine.yaml;
sops.secrets.some_secret = {
  owner = "brandon";  # optional, defaults to root
};
```

### 7. Rebuild

```bash
sudo nixos-rebuild switch --flake .
```

Secrets are decrypted to `/run/secrets/<secret_name>`.

## Reinstalling a Machine

After a reinstall, the SSH host keys change, so:

1. Derive the new age public key (step 2 above)
2. Replace the old key in `.sops.yaml`
3. Re-encrypt all secret files: `sops updatekeys secrets/<file>.yaml`
4. Rebuild

## Setting Up the Admin Key

The admin key lets you edit encrypted secrets from any machine. It only needs to exist on machines where you'll run `sops` to edit secrets.

```bash
# Generate (first time only)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Or copy from another machine
scp other-machine:~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt
```

The admin public key is `age18evrtkw2u8aepymjed5wtxmddmajh7ltcpq4kk7wwrf4u6qtnv2surywn6`.

## Editing Secrets

```bash
nix shell nixpkgs#sops -c sops secrets/dreadnought.yaml
```

This decrypts the file into your `$EDITOR`, and re-encrypts on save.

## Adding a New Secret

1. Add the value to the appropriate `secrets/<hostname>.yaml` via `sops`
2. Declare it in the machine's nix config:

```nix
sops.secrets.my_secret = {
  owner = "brandon";  # if a non-root service needs it
};
```

3. Reference it where needed:

```nix
services.something.environmentFile = config.sops.secrets.my_secret.path;
```

4. Rebuild.
