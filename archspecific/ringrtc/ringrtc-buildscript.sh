#!/bin/bash

set -x

export PATH=$(pwd)/depot_tools/:/opt/node/bin/:$PATH
cd ringrtc
mkdir -p .cargo
#cat << HEREDOC > .cargo/config.toml
#[target.ARCHSPECIFICVARIABLELONG-unknown-linux-gnu]
#linker = "ARCHSPECIFICVARIABLELONG-linux-gnu-gcc"
#HEREDOC 
echo -e '[target.ARCHSPECIFICVARIABLELONG-unknown-linux-gnu]\nlinker = "ARCHSPECIFICVARIABLELONG-linux-gnu-gcc"' > .cargo/config.toml

source ~/.cargo/env

rustup toolchain install 1.51.0
rustup default 1.51.0
rustup target add ARCHSPECIFICVARIABLELONG-unknown-linux-gnu
make electron PLATFORM=unix NODEJS_ARCH=ARCHSPECIFICVARIABLESHORT
# This file doesn't exist until the above has failed...
./src/webrtc/src/build/linux/sysroot_scripts/install-sysroot.py --arch=amd64
make electron PLATFORM=unix NODEJS_ARCH=ARCHSPECIFICVARIABLESHORT
cp src/node/build/linux/libringrtc-amd64.node ../..
