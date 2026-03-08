# Full home-manager config for personal desktop machines.
# Imports base (shared CLI tools) + desktop (GUI, fonts, syncthing, etc.).
{
  ...
}:
{
  imports = [
    ./base.nix
    ./desktop.nix
  ];
}
