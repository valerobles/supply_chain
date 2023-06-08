#!/usr/bin/env bash

set -eo pipefail


echo "Checking Canister.mo compiles"
moc matchers/Canister.mo

moc  -wasi-system-api Test.mo
wasmtime Test.wasm