{
  self,
  nixpkgs,
  system,
  toolchain,
}:
let
  inherit (toolchain)
    projectSource
    pkgsFor
    rocFor
    redisPyVersion
    redisRsVersion
    rocRedisClientVersion
    goRedisVersion
    benchmarkBuildMode
    benchmarkNixSourceId
    pythonBenchmarkFor
    platformArchives
    primeBasicCliCache
    primeWebserverCache
    primeFuzzCache
    projectRocFor
    ;
  pkgs = pkgsFor.${system};
  roc = rocFor system;
  archives = platformArchives pkgs;
  projectRoc = projectRocFor pkgs roc archives;
  poolingClient = import ./pooling.nix {
    inherit pkgs roc projectSource;
    inherit (toolchain) rocCompilerCommit;
  };
  systemParts = nixpkgs.lib.splitString "-" system;
  benchmarkArch = builtins.elemAt systemParts 0;
  benchmarkOs = builtins.elemAt systemParts 1;
  prepareRuntimeCache = cacheContents: ''
    ROC_RUNTIME_STATE_DIR="$(mktemp -d)"
    HOME="$ROC_RUNTIME_STATE_DIR/home"
    ROC_CACHE_DIR="$ROC_RUNTIME_STATE_DIR/compiler-cache"
    export HOME ROC_CACHE_DIR ROC_RUNTIME_STATE_DIR
    mkdir -p "$HOME"
    cleanup_roc_cache() {
      chmod -R u+w "$ROC_RUNTIME_STATE_DIR"
      rm -rf -- "$ROC_RUNTIME_STATE_DIR"
    }
    trap cleanup_roc_cache EXIT
    ${cacheContents}

    # Preserve exec/signal semantics for the Roc harness while still
    # removing the writable cache if it is terminated abruptly.
    cache_owner_pid=$$
    (
      while kill -0 "$cache_owner_pid" 2>/dev/null; do
        sleep 1
      done
      chmod -R u+w "$ROC_RUNTIME_STATE_DIR" 2>/dev/null || true
      rm -rf -- "$ROC_RUNTIME_STATE_DIR"
    ) </dev/null >/dev/null 2>&1 &
    trap - EXIT
  '';
  pythonBenchmark = pythonBenchmarkFor pkgs;
  buildBasicCliApp =
    {
      name,
      binary,
      sourcePath,
      buildMode ? "dev",
    }:
    pkgs.runCommand name
      {
        nativeBuildInputs = [
          pkgs.coreutils
          roc
        ];
        src = projectSource;
      }
      ''
        export HOME="$TMPDIR/home"
        export ROC_CACHE_DIR="$TMPDIR/roc-cache"
        mkdir -p "$HOME" "$out/bin"
        ${primeBasicCliCache archives}
        cp -R "$src" source
        chmod -R u+w source
        cd source
        timeout 300 roc build --opt=${buildMode} ${sourcePath} --output="$out/bin/${binary}"
      '';
  goBenchmarkSubject = pkgs.buildGoModule {
    pname = "roc-redis-go-benchmark";
    version = "0.1.0";
    # A source root literally named `go` is treated as GOPATH by the
    # toolchain, which disables module discovery. Give the fixed source
    # tree an unambiguous name.
    src = builtins.path {
      path = ../benchmarks/go;
      name = "roc-redis-go-benchmark-source";
    };
    vendorHash = "sha256-Hd8B/FOthfJfEDMn1JwNfwIpsGgr1kfHkPjCx+GYDvI=";
    subPackages = [ "." ];
    postInstall = ''
      mv "$out/bin/go" "$out/bin/roc-redis-go-benchmark"
    '';
  };
  rustBenchmarkSubject = pkgs.rustPlatform.buildRustPackage {
    pname = "roc-redis-rust-benchmark";
    version = "0.1.0";
    src = pkgs.lib.cleanSourceWith {
      src = ../benchmarks/rust;
      filter = path: type: builtins.baseNameOf path != "target";
    };
    cargoLock.lockFile = ../benchmarks/rust/Cargo.lock;
    ROC_REDIS_RUST_VERSION = pkgs.rustc.version;
  };
  cBenchmarkSubject = pkgs.stdenv.mkDerivation {
    pname = "roc-redis-c-benchmark";
    version = "0.1.0";
    src = ../benchmarks/c;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.hiredis ];
    buildPhase = ''
      runHook preBuild
      $CC -std=c11 -O3 -Wall -Wextra -Werror '-DROC_REDIS_C_VERSION="${pkgs.stdenv.cc.version}"' '-DROC_REDIS_HIREDIS_VERSION="${pkgs.hiredis.version}"' benchmark.c $(pkg-config --cflags --libs hiredis) -o roc-redis-c-benchmark
      $CC -std=c11 -O2 -UNDEBUG -Wall -Wextra -Werror -Wno-unused-function test.c $(pkg-config --cflags --libs hiredis) -o test-benchmark
      $CC -std=c11 -O3 -Wall -Wextra -Werror -Wno-unused-function '-DROC_REDIS_C_VERSION="${pkgs.stdenv.cc.version}"' '-DROC_REDIS_HIREDIS_VERSION="${pkgs.hiredis.version}"' codec.c $(pkg-config --cflags --libs hiredis) -o roc-redis-c-codec
      runHook postBuild
    '';
    doCheck = true;
    checkPhase = ''
      ./test-benchmark
      ./roc-redis-c-codec 100 1 1 check 0
    '';
    installPhase = ''
      mkdir -p "$out/bin"
      cp roc-redis-c-benchmark "$out/bin/"
      cp roc-redis-c-codec "$out/bin/"
    '';
  };
  rocBenchmarkSubject = buildBasicCliApp {
    name = "roc-redis-roc-benchmark";
    binary = "roc-redis-benchmark";
    sourcePath = "benchmarks/roc.roc";
    buildMode = benchmarkBuildMode;
  };
  benchmarkController = buildBasicCliApp {
    name = "roc-redis-benchmark-controller";
    binary = "roc-redis-benchmark-controller";
    sourcePath = "scripts/benchmark.roc";
  };
  codecSubject = buildBasicCliApp {
    name = "roc-redis-codec-controller";
    binary = "roc-redis-codec";
    sourcePath = "benchmarks/codec.roc";
    buildMode = benchmarkBuildMode;
  };
  stagesSubject = buildBasicCliApp {
    name = "roc-redis-stages-controller";
    binary = "roc-redis-stages";
    sourcePath = "benchmarks/stages.roc";
    buildMode = benchmarkBuildMode;
  };
  decodeSubject = buildBasicCliApp {
    name = "roc-redis-decode-controller";
    binary = "roc-redis-decode";
    sourcePath = "benchmarks/decode.roc";
    buildMode = benchmarkBuildMode;
  };
  memorySubject = buildBasicCliApp {
    name = "roc-redis-memory-controller";
    binary = "roc-redis-memory";
    sourcePath = "benchmarks/memory.roc";
    buildMode = benchmarkBuildMode;
  };
  memoryProfileController = buildBasicCliApp {
    name = "roc-redis-memory-profile-controller";
    binary = "roc-redis-memory-profile";
    sourcePath = "scripts/profile-memory.roc";
  };
  backendController = buildBasicCliApp {
    name = "roc-redis-backend-controller";
    binary = "roc-redis-backends";
    sourcePath = "scripts/test-backends.roc";
  };
  redisIntegrationController = buildBasicCliApp {
    name = "roc-redis-integration-controller";
    binary = "roc-redis-integration-controller";
    sourcePath = "scripts/test-integration.roc";
  };
  webserverIntegrationController = buildBasicCliApp {
    name = "roc-redis-webserver-integration-controller";
    binary = "roc-redis-webserver-integration-controller";
    sourcePath = "scripts/test-basic-webserver.roc";
  };
  catalogController = buildBasicCliApp {
    name = "roc-redis-command-catalog-controller";
    binary = "roc-redis-command-catalog-controller";
    sourcePath = "scripts/command-catalog.roc";
  };
in
nixpkgs.lib.filterAttrs
  (
    name: _:
    name != "fuzz"
    || builtins.elem system [
      "aarch64-darwin"
      "x86_64-linux"
    ]
  )
  {
    inherit roc;

    # roc-fuzz currently publishes these two native platform targets.
    fuzz =
      pkgs.runCommand "roc-redis-fuzz-targets"
        {
          nativeBuildInputs = [
            roc
            pkgs.coreutils
          ];
          src = projectSource;
          meta.platforms = [
            "aarch64-darwin"
            "x86_64-linux"
          ];
        }
        ''
          export HOME="$TMPDIR/home"
          export ROC_CACHE_DIR="$TMPDIR/roc-cache"
          mkdir -p "$HOME" "$out/bin"
          ${primeFuzzCache archives}
          cp -R "$src" source
          chmod -R u+w source
          cd source
          timeout 30 roc fmt --check integration/fuzz/*.roc
          for target in resp_round_trip resp_differential resp_mutations command_encoding; do
            # Roc returns 2 for the upstream platform's version-pin warning.
            status=0
            timeout 300 roc build --fuzz "integration/fuzz/$target.roc" --output="$out/bin/$target" || status=$?
            test "$status" -eq 0 || test "$status" -eq 2
            test -x "$out/bin/$target"
          done
        '';

    roc-project = projectRoc;

    benchmark-go = goBenchmarkSubject;
    benchmark-rust = rustBenchmarkSubject;
    benchmark-c = cBenchmarkSubject;
    benchmark-python = pythonBenchmark;
    benchmark-roc = rocBenchmarkSubject;
    benchmark-codec = pkgs.writeShellApplication {
      name = "roc-redis-codec";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        export ROC_REDIS_CODEC_C=${cBenchmarkSubject}/bin/roc-redis-c-codec
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
        export ROC_REDIS_BUILD_MODE=${benchmarkBuildMode}
        exec ${codecSubject}/bin/roc-redis-codec "$@"
      '';
    };

    benchmark-stages = pkgs.writeShellApplication {
      name = "roc-redis-stages";
      text = ''
        export ROC_REDIS_STAGE_VARIANT=${benchmarkBuildMode}
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
        exec ${stagesSubject}/bin/roc-redis-stages "$@"
      '';
    };

    transport-profile = pkgs.writeShellApplication {
      name = "roc-redis-transport-profile";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.redis
        roc
      ];
      text = ''
        ${prepareRuntimeCache (primeBasicCliCache archives)}
        export ROC_REDIS_TRACE_TRANSPORT=1
        cd ${projectSource}
        exec ${redisIntegrationController}/bin/roc-redis-integration-controller "$@"
      '';
    };

    benchmark-decode = pkgs.writeShellApplication {
      name = "roc-redis-decode";
      text = ''
        export ROC_REDIS_BUILD_MODE=${benchmarkBuildMode}
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
        exec ${decodeSubject}/bin/roc-redis-decode "$@"
      '';
    };
    memory-profile = pkgs.writeShellApplication {
      name = "roc-redis-memory-profile";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.time
      ];
      text = ''
        export ROC_REDIS_MEMORY_PROBE=${self.packages.${system}.memory-probe}/bin/roc-redis-memory
        export ROC_REDIS_BUILD_MODE=${benchmarkBuildMode}
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
          exec ${memoryProfileController}/bin/roc-redis-memory-profile "$@"
      '';
    };
    memory-probe = pkgs.writeShellApplication {
      name = "roc-redis-memory";
      text = ''
        export ROC_REDIS_BUILD_MODE=${benchmarkBuildMode}
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
        exec ${memorySubject}/bin/roc-redis-memory "$@"
      '';
    };
    backend-check = pkgs.writeShellApplication {
      name = "roc-redis-backends";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.curl
        pkgs.redis
        roc
      ];
      text = ''
        ${prepareRuntimeCache (primeWebserverCache archives)}
        cd ${projectSource}
        exec ${backendController}/bin/roc-redis-backends "$@"
      '';
    };

    pooling-demo = pkgs.writeShellApplication {
      name = "roc-redis-pooling-demo";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.redis
        roc
      ];
      text = ''
        ${prepareRuntimeCache (primeBasicCliCache archives)}
        export ROC_REDIS_TEST_CLIENT=${poolingClient}/bin/roc-redis-pooling-client
        cd ${projectSource}
        exec ${redisIntegrationController}/bin/roc-redis-integration-controller "$@"
      '';
    };

    redis-integration = pkgs.writeShellApplication {
      name = "roc-redis-integration";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.redis
        roc
      ];
      text = ''
        ${prepareRuntimeCache (primeBasicCliCache archives)}
        cd ${projectSource}
        exec ${redisIntegrationController}/bin/roc-redis-integration-controller "$@"
      '';
    };

    webserver-integration = pkgs.writeShellApplication {
      name = "roc-redis-webserver-integration";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.curl
        pkgs.redis
        roc
      ];
      text = ''
        ${prepareRuntimeCache (primeWebserverCache archives)}
        cd ${projectSource}
        exec ${webserverIntegrationController}/bin/roc-redis-webserver-integration-controller "$@"
      '';
    };

    catalog-live = pkgs.writeShellApplication {
      name = "roc-redis-catalog-live";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.redis
      ];
      text = ''
        cd ${projectSource}
        exec ${catalogController}/bin/roc-redis-command-catalog-controller check --live "$@"
      '';
    };

    benchmark = pkgs.writeShellApplication {
      name = "roc-redis-benchmark";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.redis
      ];
      text = ''
        export ROC_REDIS_ROC_BENCHMARK=${rocBenchmarkSubject}/bin/roc-redis-benchmark
        export ROC_REDIS_PYTHON=${pythonBenchmark}/bin/python3
        export ROC_REDIS_PYTHON_BENCHMARK=${projectSource}/benchmarks/python/benchmark.py
        export ROC_REDIS_GO_BENCHMARK=${goBenchmarkSubject}/bin/roc-redis-go-benchmark
        export ROC_REDIS_RUST_BENCHMARK=${rustBenchmarkSubject}/bin/roc-redis-rust-benchmark
        export ROC_REDIS_C_BENCHMARK=${cBenchmarkSubject}/bin/roc-redis-c-benchmark
        export ROC_REDIS_ROC_CLIENT_VERSION=${rocRedisClientVersion}
        export ROC_REDIS_PYTHON_CLIENT_VERSION=${redisPyVersion}
        export ROC_REDIS_GO_CLIENT_VERSION=${goRedisVersion}
        export ROC_REDIS_RUST_CLIENT_VERSION=${redisRsVersion}
        export ROC_REDIS_C_CLIENT_VERSION=${pkgs.hiredis.version}
        export ROC_REDIS_NIX_SOURCE_ID=${benchmarkNixSourceId}
        export ROC_REDIS_BUILD_MODE=${benchmarkBuildMode}
        export ROC_REDIS_NIX_SYSTEM=${system}
        export ROC_REDIS_OS=${benchmarkOs}
        export ROC_REDIS_ARCH=${benchmarkArch}
        export ROC_REDIS_GREP=${pkgs.gnugrep}/bin/grep
        exec ${benchmarkController}/bin/roc-redis-benchmark-controller "$@"
      '';
    };
  }
