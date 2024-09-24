{
  description = "my flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{ flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        globalConfig = (pkgs.formats.toml { }).generate "helix.config.toml" (
          import ./config.nix { inherit pkgs lib; }
        );
        languagesConfig = (pkgs.formats.toml { }).generate "languages.config.toml" (
          import ./languages.nix { inherit pkgs lib; }
        );

        runtime = pkgs.runCommand "helix-runtime" { } ''
          mkdir -p $out
          ln -s ${inputs.helix.outPath}/runtime/* $out
          rm -r $out/grammars
          ln -s ${pkgs.callPackage "${inputs.helix.outPath}/grammars.nix" { }} $out/grammars
        '';

        thirdPartyPkgsPath = lib.makeBinPath (with pkgs; [ nixd ]);

        xdg_config_home = pkgs.runCommand "languageConfigDir" { } ''
          mkdir -p $out/helix
          ln -s ${languagesConfig} $out/helix/languages.toml        
        '';

        helixPkg = inputs.helix.packages.${system}.helix-unwrapped;
      in
      {
        packages.default =
          pkgs.runCommand helixPkg.name
            {
              inherit (helixPkg) pname version meta;
              nativeBuildInputs = with pkgs; [ makeWrapper ];
            }
            ''
              cp -rs --no-preserve=mode,ownership ${helixPkg} $out
              wrapProgram "$out/bin/hx" \
                --set HELIX_RUNTIME ${runtime} \
                --set XDG_CONFIG_HOME ${xdg_config_home} \
                --add-flags """--config ${globalConfig}""" \
                --prefix PATH : ${thirdPartyPkgsPath}
            '';
      }
    );

  nixConfig = {
    extra-substituters = [ "https://helix.cachix.org" ];
    extra-trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
  };
}
