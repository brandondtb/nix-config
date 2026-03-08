# Shared home-manager configuration for all machines (desktops and servers).
# CLI tools, dev environments, git, ssh, zsh, tmux, neovim, etc.
# Desktop-only config lives in desktop.nix.
{
  config,
  pkgs,
  lib,
  inputs,
  self,
  secondaryTailnets,
  ...
}:
{
  home.username = lib.mkDefault "brandon";

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # Network
    curl
    dnsutils
    iperf3
    libressl.nc
    mosh
    mtr
    nmap
    speedtest-cli
    traceroute
    wget
    whois

    # Databases
    # pgcli  # TODO: Uncomment when no longer broken
    sqlite

    # Cloud & infrastructure
    awscli2
    ssm-session-manager-plugin
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    google-cloud-sql-proxy
    kubectl
    kubernetes-helm
    terraform
    terraform-lsp

    # Containers
    dive # Installing via nix works except for the socket

    # CLI tools & services
    _1password-cli
    aider-chat
    auth0-cli
    gemini-cli
    gh
    opencode
    stripe-cli

    # Node
    nodejs
    nodePackages.prettier
    mermaid-cli

    # Python
    python3
    python3Packages.black
    python3Packages.httpie
    python3Packages.pip
    python3Packages.pip-tools
    python3Packages.virtualenv
    uv

    # Linters & formatters
    djlint
    nixfmt
    pyright
    stylua

    # Document conversion
    md2pdf

    # General utilities
    elinks
    gcc
    gtypist
    jless
    jq
    just
    nh
    ripgrep
    pwgen
    sops
    tree
    w3m
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
  };

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };
    }
    // builtins.mapAttrs (name: cfg: {
      host = cfg.sshMatch;
      proxyCommand = "${pkgs.libressl.nc}/bin/nc -X 5 -x localhost:${toString cfg.socks5Port} %h %p";
    }) secondaryTailnets;
  };

  # Direnv
  programs.direnv = {
    enable = true;

    enableZshIntegration = true;
  };

  # Git
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Brandon Beveridge";
        email = "brandon@radiation.io";
      };
      pull.rebase = true;
    };
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    memory.source = ../claude/CLAUDE.md;

    mcpServers = {
      linear-rad = {
        type = "sse";
        url = "https://mcp.linear.app/sse";
      };
      linear-vody = {
        type = "sse";
        url = "https://mcp.linear.app/sse";
      };
      todoist = {
        type = "http";
        url = "https://ai.todoist.net/mcp";
      };
      atlassian = {
        type = "http";
        url = "https://mcp.atlassian.com/v1/mcp";
      };
      vanta-vody = {
        command = "node";
        args = [ "/home/brandon/src/vody/vanta-mcp-server/build/index.js" ];
        env = {
          VANTA_ENV_FILE = "/home/brandon/src/vody/vanta-mcp-server/vanta-credentials.env";
        };
      };
    };

    settings = {
      alwaysThinkingEnabled = true;
      attribution = {
        commit = "";
        pr = "";
      };
      permissions = {
        allow = [
          "Bash(git:*)"
          "Bash(gh:*)"
          "Bash(pnpm:*)"
          "Bash(uv:*)"
          "Bash(ruff:*)"
          "Bash(biome:*)"
          "Bash(pytest:*)"
          "Bash(vitest:*)"
          "Bash(cat:*)"
          "Bash(docker:*)"
          "Bash(docker-compose:*)"
          "Bash(terraform:*)"
          "mcp__linear-rad__get_*"
          "mcp__linear-rad__list_*"
          "mcp__linear-rad__search_*"
          "mcp__linear-rad__extract_*"
          "mcp__linear-vody__get_*"
          "mcp__linear-vody__list_*"
          "mcp__linear-vody__search_*"
          "mcp__linear-vody__extract_*"
          "mcp__vanta-vody__get_*"
          "mcp__vanta-vody__list_*"
          "mcp__vanta-vody__search_*"
          "WebSearch"
          "WebFetch"
        ];
      };
    };
  };

  # Opencode - global config at ~/.config/opencode/opencode.json
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "manual";
    permission = {
      "*" = "ask";
      bash = {
        "*" = "ask";
        "git *" = "allow";
        "gh *" = "allow";
        "pnpm *" = "allow";
        "uv *" = "allow";
        "ruff *" = "allow";
        "biome *" = "allow";
        "pytest *" = "allow";
        "vitest *" = "allow";
        "cat *" = "allow";
        "docker *" = "allow";
        "docker-compose *" = "allow";
        "terraform *" = "allow";
      };
      read = "allow";
      edit = "allow";
      glob = "allow";
      grep = "allow";
      list = "allow";
      webfetch = "allow";
      websearch = "allow";
    };
    mcp = {
      linear-rad = {
        type = "remote";
        url = "https://mcp.linear.app/sse";
      };
      linear-vody = {
        type = "remote";
        url = "https://mcp.linear.app/sse";
      };
      todoist = {
        type = "remote";
        url = "https://ai.todoist.net/mcp";
      };
      vanta-vody = {
        type = "local";
        command = [
          "node"
          "/home/brandon/src/vody/vanta-mcp-server/build/index.js"
        ];
        environment = {
          VANTA_ENV_FILE = "/home/brandon/src/vody/vanta-mcp-server/vanta-credentials.env";
        };
      };
    };
  };

  # Opencode - global AGENTS.md
  xdg.configFile."opencode/AGENTS.md".source = ../opencode/AGENTS.md;

  # Zsh
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 5000;
    };

    defaultKeymap = "emacs";

    zplug = {
      enable = true;

      plugins = [
        {
          name = "dracula/zsh";
          tags = [ "as:theme" ];
        }
      ];
    };

    shellAliases = {
    };

    initContent = ''
      # Source secrets (contains OP_SERVICE_ACCOUNT_TOKEN)
      [[ -f ~/.secrets ]] && source ~/.secrets

      unsetopt pathdirs

      __git_files () {
        _wanted files expl 'local files' _files
      }

      # Override prompt on servers with a red hostname to prevent prod accidents
      case "$(hostname)" in
        zoneseek)
          PROMPT="%F{red}%B[PROD]%b %F{red}%m%f %F{blue}%~%f %F{red}❯%f "
          ;;
      esac
    '';
  };

  # Tmux
  programs.tmux = {
    enable = true;
    historyLimit = 50000;
    prefix = "C-a";
    terminal = "tmux-256color";
    baseIndex = 1;
    escapeTime = 0;
    mouse = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      yank
      tokyo-night-tmux
      tmux-fzf
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-processes 'claude "~pnpm dev"'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = ''
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r C-h resize-pane -L 5
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5
      bind -r C-l resize-pane -R 5

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
      bind N new-session
      bind s choose-tree -sO name

      # Session path management
      bind P display-message -d 0 '#{session_path}'
      bind M attach-session -c '#{pane_current_path}' \; display-message -d 0 'Session path: #{pane_current_path}'
      bind C-p command-prompt -p "Session path:" "attach-session -c '%%'"

      set -g focus-events on
      set -g allow-rename off
      set -g set-clipboard on
      set -ga update-environment "WAYLAND_DISPLAY"
    '';
  };

  # Neovim
  programs.neovim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = [
      { plugin = pkgs.vimPlugins.tokyonight-nvim; }

      { plugin = pkgs.vimPlugins.plenary-nvim; }
      { plugin = pkgs.vimPlugins.nvim-web-devicons; }
      { plugin = pkgs.vimPlugins.nui-nvim; }
      { plugin = pkgs.vimPlugins.neo-tree-nvim; }

      { plugin = pkgs.vimPlugins.obsidian-nvim; }

      { plugin = pkgs.vimPlugins.nvim-lspconfig; } # LSP Configs https://github.com/neovim/nvim-lspconfig
      { plugin = pkgs.vimPlugins.lspkind-nvim; } # Pictograms for LSP

      { plugin = pkgs.vimPlugins.luasnip; }

      { plugin = pkgs.vimPlugins.which-key-nvim; }

      { plugin = pkgs.vimPlugins.copilot-lua; }

      # cmp
      { plugin = pkgs.vimPlugins.cmp_luasnip; }
      { plugin = pkgs.vimPlugins.cmp-buffer; }
      { plugin = pkgs.vimPlugins.cmp-path; }
      { plugin = pkgs.vimPlugins.cmp-cmdline; }
      { plugin = pkgs.vimPlugins.nvim-cmp; }
      { plugin = pkgs.vimPlugins.cmp-nvim-lsp; }

      {
        plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
          p.bash
          p.css
          p.csv
          p.dockerfile
          p.go
          p.hcl
          p.html
          p.javascript
          p.json
          p.lua
          p.markdown
          p.markdown_inline
          p.nix
          p.python
          p.rust
          p.sql
          p.terraform
          p.toml
          p.tsx
          p.typescript
          p.vim
          p.vimdoc
          p.yaml
        ]);
      }

      { plugin = pkgs.vimPlugins.telescope-nvim; }
      { plugin = pkgs.vimPlugins.telescope-ui-select-nvim; }

      { plugin = pkgs.vimPlugins.neoformat; } # Probably not needed

      # Claude Code integration
      { plugin = pkgs.vimPlugins.snacks-nvim; }
      { plugin = pkgs.vimPlugins.claudecode-nvim; }
    ];

    initLua = lib.fileContents ./neovim.lua;
  };
}
