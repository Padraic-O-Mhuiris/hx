{ pkgs, inputs, system, ... }:

let
  inherit (pkgs) lib; 
  tomlFormat = pkgs.formats.toml {};
  hxPkg = inputs.helix.packages.${system}.default;

  auxiliaryPkgs = with pkgs; [nixfmt-rfc-style nil bash-language-server ];

  ctxPackage =  (pkgs.symlinkJoin {
    name = "${lib.getName hxPkg}-wrapped-${lib.getVersion hxPkg}";
    paths = [pkgs.helix];
    preferLocalBuild = true;
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/hx \
        --prefix PATH : ${lib.makeBinPath auxiliaryPkgs}
    '';
  });

  meta = ctxPackage.meta // { inherit (hxPkg.meta) mainProgram; };
  finalPackage = ctxPackage // { inherit meta; };

  config = tomlFormat.generate "helix.config.toml" (import ./config.nix {});

in pkgs.writeShellScriptBin "helix" ''
  exec ${lib.getExe finalPackage} --config ${config} $@
''
