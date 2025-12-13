#!/bin/bash
echo "###ci-build.sh###"
set -x

if [ "$1" == "amd64" ]; then
	ARCHSPECIFICVARIABLECOMMON="amd64"
	ARCHSPECIFICVARIABLESHORT="x64"
fi

if [ "$1" == "arm64" ]; then
	ARCHSPECIFICVARIABLECOMMON="arm64"
	ARCHSPECIFICVARIABLESHORT="arm64"
fi

NODE_VERSION=v22.21.1

shopt -s localvar_inherit
podman create --name=signal-desktop-"$VERSION" --arch "$ARCHSPECIFICVARIABLECOMMON" -it ghcr.io/signalflatpak/image:latest bash
#podman create --name=signal-desktop-"$VERSION" --arch "$ARCHSPECIFICVARIABLECOMMON" -it debian:bookworm bash
podman start signal-desktop-"$VERSION"
podman exec -it --env="PATH=/opt/node/bin:$PATH" signal-desktop-"$VERSION" apt -qq update
#podman exec -it --env="PATH=/opt/node/bin:$PATH" signal-desktop-"$VERSION" apt -qq install -y python3 gcc g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 ruby ruby-dev curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl wget libpixman-1-dev libcairo2-dev libpango1.0-dev
podman exec -it --env="PATH=/opt/node/bin:$PATH" signal-desktop-"$VERSION" git clone -q https://github.com/signalapp/Signal-Desktop -b 7.82.x
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /opt/ signal-desktop-"$VERSION" wget -q https://nodejs.org/dist/"$NODE_VERSION"/node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /opt/ signal-desktop-"$VERSION" tar xf node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /opt/ signal-desktop-"$VERSION"  mv node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT" node
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" git-lfs install
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" git config --global user.name name
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" git config --global user.email name@example.com
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" sed -i -e 's/        "deb"/        "dir"/' package.json
# The mock tests are broken on custom arm builds
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" sed -r '/mock/d' -i package.json
# Dry run
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" npm install -g pnpm
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" npm install -g cross-env
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" npm install -g npm-run-all
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" pnpm install
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" rm -rf ts/test-mock
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" pnpm run generate
# sticker creator
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop/sticker-creator signal-desktop-"$VERSION" pnpm install
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop/sticker-creator signal-desktop-"$VERSION" pnpm run build
podman exec -it --env="PATH=/opt/node/bin:$PATH" -w /Signal-Desktop signal-desktop-"$VERSION" pnpm run build:release --"$ARCHSPECIFICVARIABLESHORT" --linux

podman cp signal-desktop-"$VERSION":/Signal-Desktop ~/Signal-Desktop_"$ARCHSPECIFICVARIABLECOMMON"
