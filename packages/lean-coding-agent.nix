{ pkgs }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "coding-agent";
  version = "0-unstable-2025-06-07";

  src = pkgs.fetchFromGitHub {
    owner = "ergodic-flow";
    repo = "lean-coding-agent";
    rev = "3bd9fd4f554ab5e5f722ee086a2d2cc9d918efac";
    hash = "sha256-52+KZ7gY6odz0kqlxNRg7zW47tLx4PP9WrjXfMsKLu4=";
  };

  cargoHash = "sha256-HSdrKRtiNo509IdmwFMBzzdXSi51XSELpcYhoXEnzXU=";

  meta = with pkgs.lib; {
    description = "Lean and mean TUI coding agent inspired by Vim and Pi";
    homepage = "https://github.com/ergodic-flow/lean-coding-agent";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "coding-agent";
  };
}
