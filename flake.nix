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

        upstreamSrc = pkgs.fetchFromGitHub {
          owner = "mixxxdj";
          repo = "mixxx";
          rev = upstreamVersion;
          hash = "sha256-G4jRr6MyXov6j6rtF9Lulk1HmyMXdmPq9JsoY6dyVXU=";
        };

        patchDir = ./patches;
        hasPatchDir = builtins.pathExists patchDir;
        patchFiles =
          if !hasPatchDir then [ ]
          else
            let
              entries = builtins.readDir patchDir;
              patchNames = builtins.filter (name: builtins.match ".*\\.patch" name != null)
                (builtins.attrNames entries);
              sorted = builtins.sort builtins.lessThan patchNames;
            in map (name: patchDir + "/${name}") sorted;

      in {
        packages.default = pkgs.mixxx.overrideAttrs (oldAttrs: {
          version = forkVersion;
          src = upstreamSrc;
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
