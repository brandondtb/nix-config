{ pkgs }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "opencode-claude-auth-sync";
  version = "0.5.2";

  src = pkgs.fetchFromGitHub {
    owner = "lehdqlsl";
    repo = "opencode-claude-auth-sync";
    rev = "v${version}";
    hash = "sha256-8FP6XcgnC4oZjkNX1aXJts/OjbZRDCAII5I2KFge+wA=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  runtimeDeps = [
    pkgs.bash
    pkgs.nodejs
    pkgs.curl
    pkgs.jq
    pkgs.coreutils
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 sync-claude-to-opencode.sh $out/bin/sync-claude-to-opencode
    ln -s $out/bin/sync-claude-to-opencode $out/bin/claude-sync
    wrapProgram $out/bin/sync-claude-to-opencode \
      --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Sync Claude CLI OAuth credentials to OpenCode";
    homepage = "https://github.com/lehdqlsl/opencode-claude-auth-sync";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "claude-sync";
  };
}
