{ pkgs }:

let
  targetPkgs =
    p: with p; [
      # X11
      libx11
      libxext
      libxi
      libxrender
      libxtst
      libxxf86vm
      libxcomposite
      libxdamage
      libxfixes
      libxrandr
      libxcb
      xcb-util-cursor
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      libxkbfile

      # Graphics
      mesa
      libgbm
      cairo
      pango
      gdk-pixbuf
      gtk3

      # Browser (JxBrowser / Chromium)
      nss
      nspr
      cups
      dbus
      libdrm
      expat
      libxkbcommon
      libxshmfence

      # Text / fonts
      freetype
      fontconfig
      glib
      dejavu_fonts
      liberation_ttf

      # Audio
      alsa-lib
      pulseaudio

      # Accessibility
      at-spi2-core
      at-spi2-atk
      atk

      # Runtime
      gcc-unwrapped.lib
      glibc
      zlib
      zstd
      libglvnd
      krb5
      systemd
    ];

  ibkrDesktopItem = pkgs.makeDesktopItem {
    name = "ibkr-desktop";
    desktopName = "IBKR Desktop";
    comment = "Interactive Brokers desktop trading platform";
    exec = "ibkr-desktop";
    icon = "ibkr-desktop";
    terminal = false;
    type = "Application";
    categories = [
      "Office"
      "Finance"
    ];
  };

  twsDesktopItem = pkgs.makeDesktopItem {
    name = "tws";
    desktopName = "IB Trader Workstation";
    comment = "Interactive Brokers trading platform";
    exec = "tws";
    icon = "tws";
    terminal = false;
    type = "Application";
    categories = [
      "Office"
      "Finance"
    ];
  };
in
{
  tws = pkgs.buildFHSEnv {
    name = "tws";
    inherit targetPkgs;
    runScript = pkgs.writeShellScript "tws-launcher" ''
      export _JAVA_OPTIONS="''${_JAVA_OPTIONS:-} -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
      JTS_DIR="$HOME/Jts"
      LATEST=$(ls -1d "$JTS_DIR"/[0-9]* 2>/dev/null | sort -V | tail -1)
      if [ -z "$LATEST" ]; then
        echo "No TWS installation found under $JTS_DIR" >&2
        exit 1
      fi
      exec "$LATEST/tws" "$@"
    '';
    extraInstallCommands = ''
      cp -r ${twsDesktopItem}/share $out/
    '';
    meta = {
      description = "Interactive Brokers Trader Workstation";
    };
  };

  ibkr-desktop = pkgs.buildFHSEnv {
    name = "ibkr-desktop";
    inherit targetPkgs;
    runScript = pkgs.writeShellScript "ibkr-desktop-launcher" ''
      # IBKR Desktop is Qt (QtJambi 6.8 + QtWebEngine), not Swing, and it ships
      # its own Qt. The KDE session exports plugin/QML paths for the system Qt
      # (6.11), which the bundled Qt rejects at load time -- drop them so it
      # only ever looks at its own.
      unset QT_PLUGIN_PATH QML2_IMPORT_PATH QML_IMPORT_PATH
      unset QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE

      # No wayland platform plugin is bundled, so go straight to xcb rather
      # than probing wayland first and failing.
      unset WAYLAND_DISPLAY
      export QT_QPA_PLATFORM=xcb

      # libglvnd inside the FHS env only sees mesa's EGL ICD (the host driver's
      # lives under /run/opengl-driver/share, which glvnd does not scan), so EGL
      # silently falls back to llvmpipe -- software rendering on a 4090.
      export __EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d:/usr/share/glvnd/egl_vendor.d

      export QTWEBENGINE_DISABLE_SANDBOX=1

      # The install4j launcher hardcodes -Dio.qt.debug=debug and
      # -Dio.qt.log-messages=ALL, routing every Qt message through
      # java.util.logging. _JAVA_OPTIONS is applied after the command line, so
      # it wins.
      export _JAVA_OPTIONS="''${_JAVA_OPTIONS:-} -Dio.qt.debug=false -Dio.qt.log-messages=CRITICAL,FATAL"

      NTWS_DIR="$HOME/ntws"
      if [ -x "$NTWS_DIR/ntws" ]; then
        exec "$NTWS_DIR/ntws" "$@"
      fi

      # Fallback: search under ~/Jts for ntws
      JTS_DIR="$HOME/Jts"
      NTWS=$(find "$JTS_DIR" -maxdepth 2 -name "ntws" -type f 2>/dev/null | head -1)
      if [ -n "$NTWS" ]; then
        exec "$NTWS" "$@"
      fi

      echo "No IBKR Desktop installation found." >&2
      echo "Run ibkr-desktop-install to install it." >&2
      exit 1
    '';
    extraInstallCommands = ''
      cp -r ${ibkrDesktopItem}/share $out/
    '';
    meta = {
      description = "Interactive Brokers IBKR Desktop";
    };
  };

  ibkr-desktop-install = pkgs.buildFHSEnv {
    name = "ibkr-desktop-install";
    targetPkgs = p: (targetPkgs p) ++ [ p.curl ];
    runScript = pkgs.writeShellScript "ibkr-desktop-install-launcher" ''
      NTWS_INSTALLER_URL="https://download2.interactivebrokers.com/installers/ntws/latest-standalone/ntws-latest-standalone-linux-x64.sh"

      if [ -n "$1" ]; then
        chmod +x "$1"
        exec "$1"
      fi

      TMPDIR="$(mktemp -d)"
      INSTALLER="$TMPDIR/ntws-install.sh"
      echo "Downloading IBKR Desktop installer..."
      curl -fSL -o "$INSTALLER" "$NTWS_INSTALLER_URL"
      chmod +x "$INSTALLER"
      "$INSTALLER"

      # Clean up desktop files created by the installer (our package provides its own)
      rm -f "$HOME/Desktop/IBKR Desktop"*.desktop 2>/dev/null
      rm -f "$HOME/.local/share/applications/IBKR Desktop"*.desktop 2>/dev/null
    '';
    meta = {
      description = "FHS environment for installing Interactive Brokers IBKR Desktop";
    };
  };

  tws-install = pkgs.buildFHSEnv {
    name = "tws-install";
    targetPkgs = p: (targetPkgs p) ++ [ p.curl ];
    runScript = pkgs.writeShellScript "tws-install-launcher" ''
      TWS_INSTALLER_URL="https://download2.interactivebrokers.com/installers/tws/latest-standalone/tws-latest-standalone-linux-x64.sh"

      if [ -n "$1" ]; then
        chmod +x "$1"
        exec "$1"
      fi

      TMPDIR="$(mktemp -d)"
      INSTALLER="$TMPDIR/tws-install.sh"
      echo "Downloading TWS installer..."
      curl -fSL -o "$INSTALLER" "$TWS_INSTALLER_URL"
      chmod +x "$INSTALLER"
      "$INSTALLER"

      # Clean up desktop files created by the installer (our package provides its own)
      rm -f "$HOME/Desktop/Trader Workstation"*.desktop 2>/dev/null
      rm -f "$HOME/.local/share/applications/Trader Workstation"*.desktop 2>/dev/null
    '';
    meta = {
      description = "FHS environment for installing Interactive Brokers TWS";
    };
  };
}
