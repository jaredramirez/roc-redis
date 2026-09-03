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
    rocNightly
    rocFor
    redisPyVersion
    redisRsVersion
    rocRedisClientVersion
    goRedisVersion
    benchmarkBuildMode
    benchmarkNixSourceId
    basicCliPackage
    basicWebserverPackage
    rocHttpPackage
    platformArchives
    primeWebserverCache
    projectRocFor
    ;
  pkgs = pkgsFor.${system};
  roc = rocFor system;
  archives = platformArchives pkgs;
  projectRoc = projectRocFor pkgs roc archives;
  systemParts = nixpkgs.lib.splitString "-" system;
  benchmarkArch = builtins.elemAt systemParts 0;
  benchmarkOs = builtins.elemAt systemParts 1;
  rocCommand = "timeout 300 roc";
  catalogCheckArguments =
    if pkgs.redis.version == "8.10.1" then
      "check --live"
    else if system == "x86_64-darwin" then
      "check"
    else
      throw "roc-redis requires Redis 8.10.1 for live catalog verification on ${system}, but nixpkgs provides ${pkgs.redis.version}";
in
{
  benchmark-app = self.packages.${system}.benchmark;
  benchmark-go = self.packages.${system}.benchmark-go;
  benchmark-rust = self.packages.${system}.benchmark-rust;
  benchmark-c = self.packages.${system}.benchmark-c;
  benchmark-roc = self.packages.${system}.benchmark-roc;
  codec-smoke = pkgs.runCommand "roc-redis-codec-smoke" { } ''
    ${self.packages.${system}.benchmark-codec}/bin/roc-redis-codec 100 > records.jsonl
    test "$(wc -l < records.jsonl)" -eq 40
    cp records.jsonl "$out"
  '';
  stages-smoke = pkgs.runCommand "roc-redis-stages-smoke" { } ''
    ${self.packages.${system}.benchmark-stages}/bin/roc-redis-stages 20 > records.jsonl
    test "$(wc -l < records.jsonl)" -eq 30
    cp records.jsonl "$out"
  '';
  transport-profile = pkgs.runCommand "roc-redis-transport-profile-check" { } ''
    ${self.packages.${system}.transport-profile}/bin/roc-redis-transport-profile > trace.txt
    test "$(grep '"workload":"ping_pipeline"' trace.txt | grep -c '"call":"write"')" -eq 10
    cp trace.txt "$out"
  '';
  decode-smoke = pkgs.runCommand "roc-redis-decode-smoke" { } ''
    ${
      self.packages.${system}.benchmark-decode
    }/bin/roc-redis-decode mixed 32 31 10 20 42 > records.jsonl
    test "$(wc -l < records.jsonl)" -eq 10
    cp records.jsonl "$out"
  '';
  memory-smoke = pkgs.runCommand "roc-redis-memory-smoke" { } ''
    ${self.packages.${system}.memory-probe}/bin/roc-redis-memory bulk 4096 31 > "$out"
  '';
  memory-fragmented =
    pkgs.runCommand "roc-redis-memory-fragmented"
      {
        nativeBuildInputs = [ pkgs.coreutils ];
      }
      ''
        # A generous regression deadline, not a comparative timing sample.
        # The previous prefix-concat implementation exceeded this deadline.
        timeout --kill-after=5s 30s ${
          self.packages.${system}.memory-probe
        }/bin/roc-redis-memory bulk 8388608 31 > "$out"
      '';
  catalog-live-app = self.packages.${system}.catalog-live;
  redis-integration-app = self.packages.${system}.redis-integration;
  webserver-integration-app = self.packages.${system}.webserver-integration;

  project-roc-cache =
    pkgs.runCommand "roc-redis-project-roc-cache-check"
      {
        nativeBuildInputs = [ projectRoc ];
        src = projectSource;
      }
      ''
        cp -R "$src" source
        chmod -R u+w source
        cd source
        test ! -e .roc-cache
        original_home="$HOME"

        roc check integration/basic_cli.roc >basic-cli.log 2>&1 &
        basic_cli_pid=$!
        roc check integration/bundle_server.roc >bundle-server.log 2>&1 &
        bundle_server_pid=$!

        basic_cli_status=0
        bundle_server_status=0
        wait "$basic_cli_pid" || basic_cli_status=$?
        wait "$bundle_server_pid" || bundle_server_status=$?
        if [ "$basic_cli_status" -ne 0 ] || [ "$bundle_server_status" -ne 0 ]; then
          cat basic-cli.log bundle-server.log >&2
          exit 1
        fi

        test "$HOME" = "$original_home"
        test "$(readlink .roc-cache/xdg/roc/packages/${basicCliPackage.id})" = "${archives.basicCliUnpacked}"
        test "$(readlink .roc-cache/xdg/roc/packages/${basicWebserverPackage.id})" = "${archives.basicWebserverUnpacked}"
        test "$(readlink .roc-cache/xdg/roc/packages/${rocHttpPackage.id})" = "${archives.rocHttpUnpacked}"
        test -d .roc-cache/compiler
        touch "$out"
      '';

  benchmark-python =
    pkgs.runCommand "roc-redis-python-benchmark-check"
      {
        nativeBuildInputs = [
          pkgs.mypy
          pkgs.ruff
          self.packages.${system}.benchmark-python
        ];
        src = ../benchmarks/python;
      }
      ''
        cp -R "$src" source
        chmod -R u+w source
        ruff check source
        ruff format --check source
        ${self.packages.${system}.benchmark-python}/bin/python3 -m py_compile source/benchmark.py
        test "$(${
          self.packages.${system}.benchmark-python
        }/bin/python3 -c 'import redis; print(redis.__version__)')" = "$(sed -n 's/^redis==//p' source/requirements.txt)"
        PYTHONPATH=source ${
          self.packages.${system}.benchmark-python
        }/bin/python3 -m unittest discover -s source -p 'test_*.py'
        mypy --strict --python-executable=${
          self.packages.${system}.benchmark-python
        }/bin/python3 source/benchmark.py source/test_benchmark.py
        touch "$out"
      '';

  benchmark-smoke =
    pkgs.runCommand "roc-redis-benchmark-smoke"
      {
        nativeBuildInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          self.packages.${system}.benchmark
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        timeout 300 roc-redis-benchmark --iterations 10 --warmup 0 --samples 1 --pipeline-batch 4 --all-order-rotations --jsonl benchmark.jsonl >benchmark-output
        test "$(grep -Ec '^(roc-redis|redis-py|go-redis|redis-rs|hiredis) \|' benchmark-output)" -eq 20
        grep -F 'roc-redis | utc_wall_clock | ping_sequential |' benchmark-output
        grep -F 'redis-py | monotonic | ping_sequential |' benchmark-output
        grep -F 'go-redis | monotonic | ping_sequential |' benchmark-output
        grep -F 'redis-rs | monotonic | ping_sequential |' benchmark-output
        grep -F 'hiredis | monotonic | ping_sequential |' benchmark-output
        test "$(wc -l <benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"schema":"roc-redis-benchmark/v2"' benchmark.jsonl)" -eq 200
        test "$(grep -Ec '"redis_version":"[A-Za-z0-9+._-]+"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"nix_source_id":"${benchmarkNixSourceId}"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"build_mode":"${benchmarkBuildMode}"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"nix_system":"${system}"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"os":"${benchmarkOs}"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"arch":"${benchmarkArch}"' benchmark.jsonl)" -eq 200
        test "$(grep -Fc '"client_version":"${rocRedisClientVersion}"' benchmark.jsonl)" -eq 40
        test "$(grep -Fc '"client_version":"${redisPyVersion}"' benchmark.jsonl)" -eq 40
        test "$(grep -Fc '"client_version":"${goRedisVersion}"' benchmark.jsonl)" -eq 40
        test "$(grep -Fc '"client_version":"${redisRsVersion}"' benchmark.jsonl)" -eq 40
        test "$(grep -Fc '"client_version":"${pkgs.hiredis.version}"' benchmark.jsonl)" -eq 40
        for rotation in 0 1 2 3 4 5 6 7 8 9; do
          test "$(grep -Fc "\"order_rotation\":$rotation" benchmark.jsonl)" -eq 20
        done
        for position in 1 2 3 4 5; do
          test "$(grep -Fc "\"subject_position\":$position" benchmark.jsonl)" -eq 40
        done
        touch "$out"
      '';

  package =
    pkgs.runCommand "roc-redis-package-check"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.curl
          pkgs.redis
          pkgs.gnutar
          pkgs.zstd
          pkgs.diffutils
          roc
        ];
        src = projectSource;
      }
      ''
        export HOME="$TMPDIR/home"
        export ROC_CACHE_DIR="$TMPDIR/roc-cache"
        mkdir -p "$HOME"
        ${primeWebserverCache archives}
        cp -R "$src" source
        chmod -R u+w source
        cd source

        ${rocCommand} build --opt=dev scripts/test.roc --output="$TMPDIR/test-suite"
        "$TMPDIR/test-suite" check
        "$TMPDIR/test-suite" test
        # Exact-version live catalog validation is separate from the
        # portable snapshot check owned by the suite.
        ${rocCommand} build --opt=dev scripts/command-catalog.roc --output="$TMPDIR/command-catalog"
        timeout 300 "$TMPDIR/command-catalog" ${catalogCheckArguments}
        ${rocCommand} build --opt=dev scripts/test-bundle.roc --output="$TMPDIR/test-bundle"
        timeout 300 "$TMPDIR/test-bundle"
        timeout 300 ${self.packages.${system}.redis-integration}/bin/roc-redis-integration
        timeout 300 ${self.packages.${system}.webserver-integration}/bin/roc-redis-webserver-integration
        ${rocCommand} build --opt=dev scripts/check-known-bug.roc --output="$TMPDIR/check-known-bug"
        timeout 300 "$TMPDIR/check-known-bug"
        ${rocCommand} docs package/main.roc --output="$TMPDIR/docs"
        mkdir -p "$TMPDIR/bundle"
        cmp LICENSE package/LICENSE
        cmp NOTICE package/NOTICE
        ${rocCommand} bundle package/main.roc package/LICENSE package/NOTICE --output-dir "$TMPDIR/bundle"
        # Explicit bundle inputs are required for non-Roc files. Verify their
        # bytes in the distributable archive, not just the source checkout.
        archives=("$TMPDIR/bundle/"*.tar.zst)
        test "''${#archives[@]}" -eq 1
        tar --use-compress-program=unzstd -xOf "''${archives[0]}" LICENSE > "$TMPDIR/bundled-license"
        tar --use-compress-program=unzstd -xOf "''${archives[0]}" NOTICE > "$TMPDIR/bundled-notice"
        cmp LICENSE "$TMPDIR/bundled-license"
        cmp NOTICE "$TMPDIR/bundled-notice"

        touch "$out"
      '';

  roc-version =
    pkgs.runCommand "roc-version-check"
      {
        nativeBuildInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          roc
        ];
        src = projectSource;
      }
      ''
        test "$(timeout 30 roc version)" = "Roc compiler version ${rocNightly}"
        test "$(cat "$src/.roc-version")" = "${rocNightly}"
        grep -Fq 'roc: "${rocNightly}"' "$src/package/main.roc"
        grep -Fq 'roc: "${rocNightly}"' "$src/integration/bundle_consumer/main.roc"
        grep -Fq '\"runtime_version\":\"${rocNightly}\"' "$src/benchmarks/roc.roc"
        grep -Fq 'runtime: "${rocNightly}/' "$src/benchmarks/codec.roc"
        grep -Fq 'compiler: "${rocNightly}"' "$src/benchmarks/stages.roc"
        grep -Fq 'pf: platform "${basicWebserverPackage.url}"' "$src/integration/basic_webserver.roc"
        grep -Fq 'http: "${rocHttpPackage.url}"' "$src/integration/basic_webserver.roc"
        grep -Fq 'pf: platform "${basicWebserverPackage.url}"' "$src/integration/bundle_server.roc"
        grep -Fq 'http: "${rocHttpPackage.url}"' "$src/integration/bundle_server.roc"
        touch "$out"
      '';
}
//
  nixpkgs.lib.optionalAttrs
    (builtins.elem system [
      "aarch64-darwin"
      "x86_64-linux"
    ])
    {
      fuzz-smoke = pkgs.runCommand "roc-redis-fuzz-smoke" { nativeBuildInputs = [ pkgs.coreutils ]; } ''
        mkdir -p "$out"
        for target in resp_round_trip resp_differential resp_mutations command_encoding; do
          mkdir "$target"
          (cd "$target"; timeout 120 ${self.packages.${system}.fuzz}/bin/"$target" run --runs=10000 --seed=20260907 --max-input-size=512) > "$out/$target.log" 2>&1
        done
      '';
    }
