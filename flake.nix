{
  description = "A platform-agnostic Redis client package for Roc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Current nixpkgs no longer supports Intel macOS, but Roc still publishes
    # an x86_64-darwin nightly. Keep that development shell available without
    # holding the other systems back.
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # Reuse the official overlay's packaging logic. Release bytes are pinned
    # separately below because a new nightly can briefly precede its overlay
    # metadata; both inputs remain immutable and hash-verified.
    roc-overlay = {
      url = "github:roc-lang/roc-overlay/7bf73f0cba9b1258ed7248f4e3be9d29a7934618";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin,
      roc-overlay,
      ...
    }:
    let
      toolchain = import ./nix/toolchain.nix {
        inherit
          self
          nixpkgs
          nixpkgs-darwin
          roc-overlay
          ;
      };
      inherit (toolchain)
        forAllSystems
        pkgsFor
        rocFor
        platformArchives
        pythonBenchmarkFor
        projectRocFor
        ;

    in
    {
      packages = forAllSystems (
        system:
        import ./nix/packages.nix {
          inherit
            self
            nixpkgs
            system
            toolchain
            ;
        }
      );

      apps = forAllSystems (
        system:
        {
          roc-project = {
            type = "app";
            program = "${self.packages.${system}.roc-project}/bin/roc";
            meta = {
              description = "Run the pinned Roc compiler with roc-redis's hermetic project cache";
            };
          };

          redis-integration = {
            type = "app";
            program = "${self.packages.${system}.redis-integration}/bin/roc-redis-integration";
            meta = {
              description = "Run roc-redis against an isolated local Redis server";
            };
          };

          webserver-integration = {
            type = "app";
            program = "${self.packages.${system}.webserver-integration}/bin/roc-redis-webserver-integration";
            meta = {
              description = "Run roc-redis through basic-webserver against an isolated Redis server";
            };
          };

          catalog-live = {
            type = "app";
            program = "${self.packages.${system}.catalog-live}/bin/roc-redis-catalog-live";
            meta = {
              description = "Verify roc-redis's command API against the pinned Redis catalog";
            };
          };

          benchmark = {
            type = "app";
            program = "${self.packages.${system}.benchmark}/bin/roc-redis-benchmark";
            meta = {
              description = "Benchmark roc-redis against redis-py, go-redis, redis-rs, and hiredis";
            };
          };
          benchmark-codec = {
            type = "app";
            program = "${self.packages.${system}.benchmark-codec}/bin/roc-redis-codec";
            meta.description = "Compare server-free Roc and hiredis codecs";
          };
          benchmark-stages = {
            type = "app";
            program = "${self.packages.${system}.benchmark-stages}/bin/roc-redis-stages";
            meta.description = "Measure the individual Roc pipeline stages";
          };
          transport-profile = {
            type = "app";
            program = "${self.packages.${system}.transport-profile}/bin/roc-redis-transport-profile";
            meta.description = "Trace adapter calls against isolated Redis";
          };
          benchmark-decode = {
            type = "app";
            program = "${self.packages.${system}.benchmark-decode}/bin/roc-redis-decode";
            meta.description = "Run seeded decode-only workload diagnostics";
          };
          memory-probe = {
            type = "app";
            program = "${self.packages.${system}.memory-probe}/bin/roc-redis-memory";
            meta.description = "Run one bounded memory probe case";
          };
          memory-profile = {
            type = "app";
            program = "${self.packages.${system}.memory-profile}/bin/roc-redis-memory-profile";
            meta.description = "Measure bounded memory cases in separate processes";
          };
          backend-check = {
            type = "app";
            program = "${self.packages.${system}.backend-check}/bin/roc-redis-backends";
            meta.description = "Qualify selected backends using executed production tests";
          };
        }
        //
          nixpkgs.lib.optionalAttrs
            (builtins.elem system [
              "aarch64-darwin"
              "x86_64-linux"
            ])
            (
              builtins.listToAttrs (
                map
                  (target: {
                    name = "fuzz-${target}";
                    value = {
                      type = "app";
                      program = "${self.packages.${system}.fuzz}/bin/${target}";
                      meta.description = "Run the upstream roc-fuzz runner for ${target}";
                    };
                  })
                  [
                    "resp_round_trip"
                    "resp_differential"
                    "resp_mutations"
                    "command_encoding"
                  ]
              )
            )
      );

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
          roc = rocFor system;
          archives = platformArchives pkgs;
          pythonBenchmark = pythonBenchmarkFor pkgs;
          projectRoc = projectRocFor pkgs roc archives;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.bash
              pkgs.coreutils
              pkgs.curl
              pkgs.go
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.clippy
              pkgs.pkg-config
              pkgs.hiredis
              pythonBenchmark
              projectRoc
              pkgs.just
              pkgs.redis
            ];

            ROC_LANGUAGE_SERVER_PATH = "${projectRoc}/bin/roc";
            ROC_REDIS_ROC_COMMAND = "timeout 300 roc";
          };
        }
      );

      checks = forAllSystems (
        system:
        import ./nix/checks.nix {
          inherit
            self
            nixpkgs
            system
            toolchain
            ;
        }
      );
    };
}
