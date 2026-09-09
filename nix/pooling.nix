{
  pkgs,
  roc,
  projectSource,
  rocCompilerCommit,
}:
let
  # Glue must agree with the compiler's ABI, not the latest source checkout.
  compilerSource = pkgs.fetchzip {
    url = "https://github.com/roc-lang/roc/archive/${rocCompilerCommit}.tar.gz";
    hash = "sha256-aZaOzGqA+nNO90I2voB5snR05u2UONvesCqTD3Irl9g=";
  };
  target =
    {
      aarch64-darwin = "arm64mac";
      x86_64-darwin = "x64mac";
      aarch64-linux = "arm64glibc";
      x86_64-linux = "x64glibc";
    }
    .${pkgs.stdenv.hostPlatform.system};
in
pkgs.runCommand "roc-redis-pooling-client"
  {
    nativeBuildInputs = [
      roc
      pkgs.zig
      pkgs.coreutils
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.patchelf ];
  }
  ''
    export ROC_CACHE_DIR="$TMPDIR/roc-cache"
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    cp -R ${projectSource} source
    chmod -R u+w source
    cd source
    mkdir -p glue examples/pooling/platform/targets/${target} "$out/bin"
    timeout 300 roc glue ${compilerSource}/src/glue/src/ZigGlue.roc glue examples/pooling/platform/main.roc
    zig test examples/pooling/platform/pool.zig -lc
    zig build-lib -lc -O ReleaseSafe --dep abi \
      -Mroot=examples/pooling/platform/host.zig -Mabi=glue/roc_platform_abi.zig \
      -femit-bin=examples/pooling/platform/targets/${target}/libhost.a
    ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      for input in Scrt1.o crti.o crtn.o libc.so; do
        cp ${pkgs.stdenv.cc.libc}/lib/$input examples/pooling/platform/targets/${target}/
      done
    ''}
    timeout 300 roc build --opt=dev --target=${target} examples/pooling/main.roc --output="$out/bin/roc-redis-pooling-client"
    ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
        --set-rpath ${pkgs.stdenv.cc.libc}/lib "$out/bin/roc-redis-pooling-client"
    ''}
  ''
