# Tailscale Configuration

This repo runs two layers of Tailscale: a **primary** system-level instance and one or more **secondary** userspace instances that coexist alongside it.

## Primary Tailscale

Defined in `nixos/common.nix`:

```nix
services.tailscale = {
  enable = true;
  extraUpFlags = [ "--ssh" "--advertise-exit-node" ];
};
```

- Uses the standard kernel TUN device (`tailscale0`)
- `tailscale0` is added to `networking.firewall.trustedInterfaces`
- IP forwarding is enabled (`net.ipv4.ip_forward`, `net.ipv6.conf.all.forwarding`) so the node can serve as an exit node
- Starts automatically on boot
- Managed with the normal `tailscale` CLI

## Secondary Tailnets

Secondary tailnets let you connect to additional Tailscale networks without interfering with the primary instance. Configuration lives in two places:

| File | Responsibility |
|------|---------------|
| `tailscale-secondary.nix` | Declares tailnets (name, domain, SOCKS5 port, SSH match pattern) |
| `nixos/common.nix` | Generates a `systemd` service per tailnet |
| `home-manager/linux.nix` | Generates wrapper scripts and SSH `matchBlocks` per tailnet |

### How it works

Each secondary tailnet runs a separate `tailscaled` process with:

- **Userspace networking** (`--tun=userspace-networking`) — no kernel TUN device, so it coexists with the primary
- **Isolated state** — `/var/lib/tailscale-<name>/tailscaled.state` and `/run/tailscale-<name>/tailscaled.sock`
- **SOCKS5 proxy** — exposes traffic on `localhost:<socks5Port>`
- **No auto-start** (`wantedBy = []`) — brought up and down manually

### Adding a new tailnet

Add an entry to `tailscale-secondary.nix`:

```nix
{
  vody = {
    tailnetName = "tailde28d5.ts.net";
    socks5Port = 1055;
    sshMatch = "*.tailde28d5.ts.net";
  };
  another = {
    tailnetName = "tailXXXXXX.ts.net";
    socks5Port = 1056;
    sshMatch = "*.tailXXXXXX.ts.net";
  };
}
```

Each entry auto-generates:
1. A `systemd.services.tailscaled-<name>` unit
2. Wrapper scripts: `ts-<name>-up`, `ts-<name>-down`, `ts-<name>-status`
3. SSH `matchBlocks` routing `sshMatch` hosts through the SOCKS5 proxy via `nc -X 5`

### Usage

```bash
ts-vody-up          # Start the daemon and authenticate
ts-vody-status      # Show peers and tailnet info
ts-vody-down        # Disconnect and stop the daemon
```

SSH to hosts on the secondary tailnet works transparently — the generated `matchBlocks` route connections through the SOCKS5 proxy:

```bash
ssh host.tailde28d5.ts.net    # Proxied through localhost:1055 automatically
```

### Browser access

To reach web services on a secondary tailnet, configure a SOCKS5 proxy pointed at `localhost:<socks5Port>`:

#### FoxyProxy (recommended)

FoxyProxy lets you selectively proxy only tailnet traffic while keeping normal browsing direct.

1. Install [FoxyProxy Standard](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/) (Firefox) or the Chrome equivalent
2. Open FoxyProxy options and add a new proxy:
   - **Title**: e.g. `vody tailnet`
   - **Type**: SOCKS5
   - **Hostname**: `localhost`
   - **Port**: `1055` (or the tailnet's `socks5Port`)
   - Check **"Send DNS through SOCKS5 proxy"** (MagicDNS names need to resolve via the tailnet)
3. Under the proxy's **URL Patterns**, add a pattern:
   - **Pattern**: `*.tailde28d5.ts.net/*`
   - **Type**: Wildcard
   - **Whitelist** (not blacklist)
4. Set FoxyProxy's mode to **"Use proxies based on their pre-defined patterns and priorities"**

Only `*.tailde28d5.ts.net` traffic will be proxied; everything else goes direct.

#### Firefox (manual)

Settings > Network Settings > Manual proxy > SOCKS Host `localhost`, Port `1055`, SOCKS v5, check "Proxy DNS when using SOCKS v5". This proxies **all** browser traffic.

#### Chrome (CLI flag)

```bash
google-chrome-stable --proxy-server="socks5://localhost:1055"
```

This also proxies **all** browser traffic for that session.

## Architecture summary

```
┌─────────────────────────────────────────────────┐
│  Primary Tailscale                              │
│  services.tailscale (auto-start)                │
│  TUN device: tailscale0                         │
│  Standard system service                        │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Secondary: vody                                │
│  tailscaled --tun=userspace-networking          │
│  SOCKS5 on localhost:1055                       │
│  State: /var/lib/tailscale-vody/                │
│  Socket: /run/tailscale-vody/tailscaled.sock    │
│  Scripts: ts-vody-up / down / status            │
│  SSH: *.tailde28d5.ts.net → proxied via nc      │
└─────────────────────────────────────────────────┘
```
