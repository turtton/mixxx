{
  description = "Mixxx DJ software with OpenSubSonic integration (soft fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = builtins.readFile ./.upstream-version;
        upstreamVersion = builtins.replaceStrings [ "\n" " " ] [ "" "" ] version;
        forkVersion = "${upstreamVersion}-opensubsonic.1";

        patchFiles = let
          patchDir = ./patches;
          entries = builtins.readDir patchDir;
          patchNames = builtins.filter (name: builtins.match ".*\\.patch" name != null)
            (builtins.attrNames entries);
          sorted = builtins.sort builtins.lessThan patchNames;
        in map (name: patchDir + "/${name}") sorted;

      in {
        packages.default = pkgs.mixxx.overrideAttrs (oldAttrs: {
          version = forkVersion;
          patches = (oldAttrs.patches or []) ++ patchFiles;
        });

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            mixxx
          ];

          shellHook = ''
            echo "Mixxx soft fork dev shell (upstream: ${upstreamVersion})"
            echo "Run: ./scripts/fetch-upstream.sh && ./scripts/apply-patches.sh"
          '';
        };
      });
}
