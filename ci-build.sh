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

NODE_VERSION=v20.18.0

shopt -s localvar_inherit
podman create --name=signal-desktop-"$VERSION" --arch "$ARCHSPECIFICVARIABLECOMMON" -it debian:bookworm bash
podman start signal-desktop-"$VERSION"
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" signal-desktop-"$VERSION" apt -qq update
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" signal-desktop-"$VERSION" apt -qq install -y python3 gcc g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 ruby ruby-dev curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl wget
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" signal-desktop-"$VERSION" gem install fpm
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" signal-desktop-"$VERSION" git clone https://github.com/signalapp/Signal-Desktop -b 7.31.x
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /opt/ signal-desktop-"$VERSION" wget -q https://nodejs.org/dist/"$NODE_VERSION"/node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /opt/ signal-desktop-"$VERSION" tar xf node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /opt/ signal-desktop-"$VERSION"  mv node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT" node
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" git-lfs install
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" git config --global user.name name
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" git config --global user.email name@example.com
# The mock tests are broken on custom arm builds
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" sed -r '/mock/d' -i package.json
# Dry run
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" npm install --non-interactive
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" npm install --frozen-lockfile --non-interactive
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" rm -rf ts/test-mock
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" npm run generate
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" npm run build:release --"$ARCHSPECIFICVARIABLESHORT" --linux --dir
podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop signal-desktop-"$VERSION" npm run build:release --"$ARCHSPECIFICVARIABLESHORT" --linux --deb

podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" -w /Signal-Desktop/release signal-desktop-"$VERSION" mv linux-unpacked signal

podman exec -it --env="PATH=/opt/node/bin:$PATH" --env="USE_SYSTEM_FPM=true" signal-desktop-"$VERSION" ls -al /Signal-Desktop/release/
podman cp signal-desktop-"$VERSION":/Signal-Desktop/release/signal-desktop_"$VERSION"_"$ARCHSPECIFICVARIABLECOMMON".deb ~/signal-desktop.deb
