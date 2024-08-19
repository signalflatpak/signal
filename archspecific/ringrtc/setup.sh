#!/bin/bash

set -ex

exit_msg() {
	echo $1
	exit 1
}

NODE_VERSION="v16.5.0"

# DEPS
sudo apt install -y vim python gcc python2 g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl libglib2.0-dev meson gcc-linux-gnu crossbuild-essential-ARCHSPECIFICVARIABLECOMMON
sudo mkdir -p /usr/include/ARCHSPECIFICVARIABLELONG-linux-gnu/
# pulled from https://raw.githubusercontent.com/node-ffi-napi/node-ffi-napi/master/deps/libffi/config/linux/x64/fficonfig.h because its not in debian
sudo cp ../fficonfig.h /usr/include/ARCHSPECIFICVARIABLELONG-linux-gnu/
chmod +x rustup-init
./rustup-init -y

# Clone ringrtc
git clone https://github.com/signalapp/ringrtc -b v2.18.0
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$(pwd)/depot_tools:$PATH

# NODE
# Goes last because docker build can't cache the tar.
# https://nodejs.org/dist/v14.15.5/
wget -c https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz
shasum -c node.sums || exit_msg "INVALID NODE PACKAGE SHA SUM"
sudo cp node-${NODE_VERSION}-linux-x64.tar.gz /opt/
sudo mkdir -p /opt/node
pushd /opt/; sudo tar xf node-${NODE_VERSION}-linux-x64.tar.gz
sudo mv /opt/node-${NODE_VERSION}-linux-x64/* /opt/node/ || true
export PATH=/opt/node/bin:$PATH
sudo PATH=/opt/node/bin:$PATH /opt/node/bin/npm install --global yarn
popd

#
