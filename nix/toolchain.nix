{
  self,
  nixpkgs,
  nixpkgs-darwin,
  roc-overlay,
}:
let
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  forAllSystems = nixpkgs.lib.genAttrs systems;

  # `path:.` includes untracked API work, but must not copy local compiler
  # caches or build outputs into hermetic checks or benchmark provenance.
  projectSource = nixpkgs.lib.cleanSourceWith {
    src = self;
    name = "roc-redis-source";
    filter =
      path: type:
      let
        name = builtins.baseNameOf path;
      in
      nixpkgs.lib.cleanSourceFilter path type
      && !(builtins.elem name [
        ".roc-cache"
        ".jj"
        ".direnv"
        ".venv"
        ".ruff_cache"
        ".mypy_cache"
        ".roc-fuzz"
        "__pycache__"
        "target"
        "dist"
        "generated-docs"
        "results"
      ]);
  };

  pkgsFor = forAllSystems (
    system:
    if system == "x86_64-darwin" then
      nixpkgs-darwin.legacyPackages.${system}
    else
      nixpkgs.legacyPackages.${system}
  );

  # CI, Roc package headers, and benchmark metadata all share this
  # fast-moving nightly name. The four release hashes are deliberately
  # explicit so every supported development shell verifies its own native
  # compiler archive.
  rocNightly = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ../.roc-version);
  rocReleaseSuffix = nixpkgs.lib.removePrefix "nightly-" rocNightly;
  rocReleaseSource = artifactPlatform: sha256: rec {
    asset = "roc_nightly-${artifactPlatform}-${rocReleaseSuffix}.tar.gz";
    inherit sha256;
    url = "https://github.com/roc-lang/nightlies/releases/download/${rocNightly}/${asset}";
  };
  rocReleaseSources = {
    aarch64-darwin = rocReleaseSource "macos_apple_silicon" "sha256-UYH/NZaMFKvM28ft/etYEUtPV2olmHWCUQA/OfCDILs=";
    x86_64-darwin = rocReleaseSource "macos_x86_64" "sha256-N+0C0c9it9O2p7YGEfS0OFbpBoNjuhWsrS5R/qwTl1k=";
    aarch64-linux = rocReleaseSource "linux_arm64" "sha256-ic8Ltip1NHD0FWSlwEfO+6B1sigNDTUbFBqxCUPCd3s=";
    x86_64-linux = rocReleaseSource "linux_x86_64" "sha256-jrF+mLMZR1WdYg558fVkvYvJM/uAFfbEYC+zvm5gjTg=";
  };
  rocCompilerCommit = "14d98293a9918b746707d754acb1c5d945ae31c1";
  rocFor =
    system:
    let
      pkgs = pkgsFor.${system};
      source = rocReleaseSources.${system};
    in
    (roc-overlay.packages.${system}.nightly).overrideAttrs (previous: {
      version = rocNightly;
      src = pkgs.fetchurl {
        inherit (source) url;
        hash = source.sha256;
      };
      passthru = (previous.passthru or { }) // {
        compilerCommit = rocCompilerCommit;
        compilerVersion = rocNightly;
        tag = rocNightly;
        inherit source;
      };
      meta = previous.meta // {
        changelog = "https://github.com/roc-lang/nightlies/releases/tag/${rocNightly}";
      };
    });

  redisPyVersion = "8.1.0";
  redisRsVersion = "1.6.0";
  rocRedisClientVersion = "0.1.0-dev";
  goRedisModule = "github.com/redis/go-redis/v9";
  goRedisVersion =
    let
      prefix = "require ${goRedisModule} ";
      matchingLines = builtins.filter (nixpkgs.lib.hasPrefix prefix) (
        nixpkgs.lib.splitString "\n" (builtins.readFile ../benchmarks/go/go.mod)
      );
    in
    if builtins.length matchingLines == 1 then
      nixpkgs.lib.removePrefix prefix (builtins.head matchingLines)
    else
      throw "expected exactly one direct ${goRedisModule} requirement in benchmarks/go/go.mod";
  benchmarkBuildMode = "dev";
  benchmarkNixSourceId = builtins.baseNameOf (toString projectSource);
  redisPyFor =
    pkgs:
    pkgs.python3Packages.redis.overridePythonAttrs (_previous: {
      version = redisPyVersion;
      src = pkgs.fetchPypi {
        pname = "redis";
        version = redisPyVersion;
        hash = "sha256-bhoZvu+SJcg+/Wicfmt9otUhWx9CzRO3/DcU0KCceyU=";
      };
    });
  pythonBenchmarkFor = pkgs: pkgs.python3.withPackages (_pythonPackages: [ (redisPyFor pkgs) ]);

  # Roc resolves URL-backed packages through a content-addressed cache. Keep
  # the exact archives in the Nix graph as well, so flake checks and apps do
  # not depend on network access or a developer's pre-existing Roc cache.
  basicCliPackage = {
    id = "3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i";
    url = "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst";
    hash = "sha256-3vjAUtcCdgS1DWfyCanTOzqDHhcoEdPjHqHzqHMiMBg=";
  };

  # Frozen compiler repros retain their original platform. Seed both archives
  # so checking those regressions stays offline without rewriting the repros.
  basicCliReproPackage = {
    id = "9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m";
    url = "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst";
    hash = "sha256-5WQ6EAPmGN1R3Y0NSZC1S670PWv5vt22jSQDfsLvEtg=";
  };

  # roc-fuzz 0.4.0-rc1, MIT, upstream commit
  # 1fa2b5f09d77f1e91a2df3b0a11adf8454dd2831. Engine/replay/minimization
  # are reused from upstream; RESP properties are project-specific.
  fuzzPackage = {
    id = "9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc";
    url = "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst";
    hash = "sha256-4EU4Lm3LngTCmxTG5jlJ/Lh5kX8yirXHEgxTUWU7qbA=";
  };

  basicWebserverPackage = {
    id = "42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw";
    url = "https://github.com/roc-lang/basic-webserver/releases/download/0.16.0/42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw.tar.zst";
    hash = "sha256-tujSbdoP2iOzS9F5oChZFYFVprR7Z88yLKv7fT0RIn0=";
  };

  rocHttpPackage = {
    id = "6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS";
    url = "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst";
    hash = "sha256-6e+qlQ5y9vds326vAEJFcvppsEumEnMjV6wEU2ePArQ=";
  };

  unpackRocPackage =
    pkgs: id: archive:
    pkgs.runCommand "roc-package-${id}"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.zstd
        ];
      }
      ''
        mkdir -p "$out"
        tar --use-compress-program=unzstd -xf ${archive} -C "$out"
      '';

  platformArchives = pkgs: rec {
    fuzz = pkgs.fetchurl {
      inherit (fuzzPackage) url hash;
      name = "${fuzzPackage.id}.tar.zst";
    };
    fuzzUnpacked = unpackRocPackage pkgs fuzzPackage.id fuzz;
    basicCli = pkgs.fetchurl {
      inherit (basicCliPackage) url hash;
      name = "${basicCliPackage.id}.tar.zst";
    };
    basicCliRepro = pkgs.fetchurl {
      inherit (basicCliReproPackage) url hash;
      name = "${basicCliReproPackage.id}.tar.zst";
    };
    basicCliReproUnpacked = unpackRocPackage pkgs basicCliReproPackage.id basicCliRepro;
    basicWebserver = pkgs.fetchurl {
      inherit (basicWebserverPackage) url hash;
      name = "${basicWebserverPackage.id}.tar.zst";
    };
    rocHttp = pkgs.fetchurl {
      inherit (rocHttpPackage) url hash;
      name = "${rocHttpPackage.id}.tar.zst";
    };
    basicCliUnpacked = unpackRocPackage pkgs basicCliPackage.id basicCli;
    basicWebserverUnpacked = unpackRocPackage pkgs basicWebserverPackage.id basicWebserver;
    rocHttpUnpacked = unpackRocPackage pkgs rocHttpPackage.id rocHttp;
  };

  primeBasicCliCache = archives: ''
    mkdir -p "$HOME/.cache/roc/packages"
    cp -R ${archives.basicCliUnpacked} \
      "$HOME/.cache/roc/packages/${basicCliPackage.id}"
    cp -R ${archives.basicCliReproUnpacked} \
      "$HOME/.cache/roc/packages/${basicCliReproPackage.id}"
    cp -R ${archives.rocHttpUnpacked} \
      "$HOME/.cache/roc/packages/${rocHttpPackage.id}"
  '';

  primeWebserverCache = archives: ''
    ${primeBasicCliCache archives}
    cp -R ${archives.basicWebserverUnpacked} \
      "$HOME/.cache/roc/packages/${basicWebserverPackage.id}"
  '';

  primeFuzzCache = archives: ''
    mkdir -p "$HOME/.cache/roc/packages"
    cp -R ${archives.fuzzUnpacked} "$HOME/.cache/roc/packages/${fuzzPackage.id}"
  '';

  # Keep interactive compiler state inside the checkout without changing
  # the user's HOME. Package directories are immutable Nix-store symlinks;
  # creating each destination is atomic, so concurrent Roc invocations can
  # safely initialize the same fresh cache.
  projectRocFor =
    pkgs: roc: archives:
    pkgs.writeShellApplication {
      name = "roc";
      runtimeInputs = [
        pkgs.coreutils
        roc
      ];
      text = ''
        project_root="$PWD"
        while [ ! -f "$project_root/flake.nix" ] || [ ! -f "$project_root/package/main.roc" ]; do
          if [ "$project_root" = "/" ]; then
            echo "roc-redis: run the project Roc wrapper from inside the repository" >&2
            exit 2
          fi
          project_root="$(dirname "$project_root")"
        done

        project_cache="$project_root/.roc-cache"
        export XDG_CACHE_HOME="$project_cache/xdg"
        export ROC_CACHE_DIR="$project_cache/compiler"
        export ROC="${roc}/bin/roc"
        package_cache="$XDG_CACHE_HOME/roc/packages"
        mkdir -p "$package_cache" "$ROC_CACHE_DIR"

        seed_package() {
          local package_id="$1"
          local package_source="$2"
          local destination="$package_cache/$package_id"

          if [ -L "$destination" ]; then
            if [ "$(readlink "$destination")" != "$package_source" ]; then
              echo "roc-redis: refusing unexpected package-cache link at $destination" >&2
              exit 2
            fi
          elif [ -e "$destination" ]; then
            echo "roc-redis: refusing unexpected package-cache entry at $destination" >&2
            exit 2
          elif ! ln -s "$package_source" "$destination" 2>/dev/null; then
            # A concurrent invocation may have won the atomic create.
            if [ ! -L "$destination" ] || [ "$(readlink "$destination")" != "$package_source" ]; then
              echo "roc-redis: could not initialize package-cache entry $destination" >&2
              exit 2
            fi
          fi
        }

        seed_package ${basicCliPackage.id} ${archives.basicCliUnpacked}
        seed_package ${basicCliReproPackage.id} ${archives.basicCliReproUnpacked}
        seed_package ${basicWebserverPackage.id} ${archives.basicWebserverUnpacked}
        seed_package ${rocHttpPackage.id} ${archives.rocHttpUnpacked}
        seed_package ${fuzzPackage.id} ${archives.fuzzUnpacked}

        exec ${roc}/bin/roc "$@"
      '';
    };
in
{
  inherit
    forAllSystems
    projectSource
    pkgsFor
    rocNightly
    rocFor
    redisPyVersion
    redisRsVersion
    rocRedisClientVersion
    goRedisVersion
    benchmarkBuildMode
    benchmarkNixSourceId
    pythonBenchmarkFor
    basicCliPackage
    basicWebserverPackage
    rocHttpPackage
    platformArchives
    primeBasicCliCache
    primeWebserverCache
    primeFuzzCache
    projectRocFor
    ;
}
