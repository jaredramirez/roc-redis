default: test

roc := env_var_or_default("ROC_REDIS_ROC_COMMAND", "nix develop --command timeout 300 roc")

# The suite inventory and compiler exceptions live in scripts/TestSuite.roc.
check:
    {{roc}} --opt=dev scripts/test.roc -- check

# Expectations plus compiled runtime contracts; bundle proof stays explicit.
test: check
    {{roc}} --opt=dev scripts/test.roc -- test
    {{roc}} --opt=dev scripts/test-bundle.roc

# Start disposable services and exercise both supported platform adapters.
integration:
    nix run .#redis-integration
    nix run .#webserver-integration

# Verify the checked-in command catalog against the flake's exact Redis server.
catalog-live:
    nix run .#catalog-live

# Compare Roc, redis-py, go-redis, redis-rs, and hiredis on isolated Redis.
benchmark *args:
    nix run .#benchmark -- {{args}}

# Supplement live results with server-free encoding and decoding measurements.
benchmark-codec iterations="10000":
    nix run .#benchmark-codec -- {{iterations}}

benchmark-stages iterations="2000":
    nix run .#benchmark-stages -- {{iterations}}

transport-profile:
    nix run .#transport-profile

# Decoder-only cases: KIND SIZE CHUNK WIDTH ITERATIONS SEED (CHUNK=0: whole).
benchmark-decode *args:
    nix run .#benchmark-decode -- {{args}}

# One case per process; wrap the built executable in the host memory profiler.
memory-probe *args:
    nix run .#memory-probe -- {{args}}

memory-profile mode="smoke" samples="1":
    nix run .#memory-profile -- {{mode}} {{samples}}

# Upstream runner supports run/show/replay/minimize; use separate corpus per target.
fuzz target *args:
    nix run .#fuzz-{{target}} -- {{args}}

# Actually build and execute tests/adapters using the selected backends.
backend-check *backends:
    nix run .#backend-check -- {{backends}}

# Run one position-balanced campaign containing ten subject orders.
benchmark-all *args:
    nix run .#benchmark -- --all-order-rotations {{args}}

# Exercise the complete benchmark pipeline without collecting performance data.
benchmark-smoke:
    nix run .#benchmark -- --iterations 10 --warmup 0 --samples 1 --pipeline-batch 4 --all-order-rotations

# Run only the basic-webserver platform proof.
webserver-integration:
    nix run .#webserver-integration

pooling-demo:
    nix run path:.#pooling-demo

# Run portable checks, verify known compiler bugs, and exercise live adapters.
# The exact-version catalog proof remains opt-in for Intel macOS, whose
# compatibility nixpkgs input currently supplies an older Redis.
all: test roc-bug integration

# Bundle the package and test its public API from a downstream consumer.
bundle-test:
    {{roc}} --opt=dev scripts/test-bundle.roc

# Generate API documentation locally.
docs:
    {{roc}} docs package/main.roc --output=generated-docs

# Create the content-addressed package archive in dist/.
bundle:
    mkdir -p dist
    {{roc}} bundle package/main.roc package/LICENSE package/NOTICE --output-dir dist

# Verify known nightly compiler issues have exactly their documented shapes.
roc-bug:
    {{roc}} --opt=dev scripts/check-known-bug.roc

# Re-run the hermetic checks exposed by the Nix flake.
nix-check:
    nix flake check
