{
  description = "TableConfig - Tablassert";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {self, systems, nixpkgs, flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import inputs.systems;
      imports = [./nix/service.nix];
    };
}