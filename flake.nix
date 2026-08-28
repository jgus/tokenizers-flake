{
  description = "tokenizers: version-bumped ahead of nixpkgs through a Python package overlay.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version sourceRev sourceHash cargoHash;
      source = { type = "github"; owner = "huggingface"; repo = "tokenizers"; };
      overlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev:
            let
              src = final.fetchFromGitHub {
                owner = "huggingface";
                repo = "tokenizers";
                rev = sourceRev;
                hash = sourceHash;
              };
            in
            {
              tokenizers = pyprev.tokenizers.overridePythonAttrs (_: {
                inherit version src;
                doCheck = false;
                cargoDeps = final.rustPlatform.fetchCargoVendor {
                  pname = "tokenizers";
                  inherit version src;
                  sourceRoot = "${src.name}/bindings/python";
                  hash = cargoHash;
                };
              });
            })
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            tokenizers = pkgs.python3.pkgs.tokenizers;
            default = pkgs.python3.pkgs.tokenizers;
            update-version = flake-lib.lib.mkUpdateVersion {
              inherit pkgs source;
              buildAttr = "tokenizers";
              buildFailureHash = "cargoHash";
            };
            update-branches = flake-lib.lib.mkUpdateBranches {
              inherit pkgs source;
              pinSchema = "github";
            };
          };
        }) // {
      overlays.default = overlay;
    };
}
