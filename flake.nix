{
  description = "NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/master";

      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      lanzaboote,
      sops-nix,
      ...
    }@inputs:
    let
      secondaryTailnets = import ./tailscale-secondary.nix;

      hmConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self secondaryTailnets; };
        home-manager.users.brandon = import ./home-manager/home.nix;
      };

      mkNixosSystem =
        hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self secondaryTailnets; };
          modules = [
            ./nixos/common.nix
            ./cachix.nix
            hostModule

            lanzaboote.nixosModules.lanzaboote
            sops-nix.nixosModules.sops

            inputs.nix-flatpak.nixosModules.nix-flatpak

            home-manager.nixosModules.home-manager
            hmConfig
          ];
        };
    in
    {

      packages.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          twsPkgs = import ./packages/ibkr.nix { inherit pkgs; };
        in
        {
          inherit (twsPkgs)
            tws
            tws-install
            ibkr-desktop
            ibkr-desktop-install
            ;
        };

      nixosConfigurations = {
        dreadnought = mkNixosSystem ./nixos/dreadnought.nix;
        relm = mkNixosSystem ./nixos/relm.nix;
        ultros = mkNixosSystem ./nixos/ultros.nix;
      };

    };
}
