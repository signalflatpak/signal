#!/usr/bin/env bash

while getopts "a:n:v:b:" flag; do
    case "${flag}" in
        a) export ARCH=$OPTARG;;
        n) export NODE_VERSION=$OPTARG;;
	v) export VERSION=$OPTARG ;;
        b) export BRANCH=$OPTARG ;;
    esac
done

echo $VERSION $BRANCH $NODE_VERSION

if [ "$ARCH" == "amd64" ]; then
	ARCHSPECIFICVARIABLECOMMON="amd64"
	ARCHSPECIFICVARIABLESHORT="x64"
elif [ "$ARCH" == "arm64" ]; then
	ARCHSPECIFICVARIABLECOMMON="arm64"
	ARCHSPECIFICVARIABLESHORT="arm64"
else
	echo "arch not set properly; exiting"
	exit 1
fi

set -x

shopt -s localvar_inherit
podman create --name=signal-desktop-"$VERSION" --arch "$ARCHSPECIFICVARIABLECOMMON" -it ghcr.io/flatpaks/signalimage:latest bash
podman start signal-desktop-"$VERSION"

function podman_exec() {
    dir=$1
    shift 1
    podman exec -it -w $dir signal-desktop-"$VERSION" $@
}

podman_exec / git clone -q https://github.com/signalapp/Signal-Desktop -b $BRANCH

podman_exec /opt/ wget -q https://nodejs.org/dist/"$NODE_VERSION"/node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman_exec /opt/ tar xf node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT".tar.gz
podman_exec /opt/ mv node-"$NODE_VERSION"-linux-"$ARCHSPECIFICVARIABLESHORT" node

podman_exec /Signal-Desktop git-lfs install
podman_exec /Signal-Desktop git config --global user.name name
podman_exec /Signal-Desktop git config --global user.email name@example.com

#podman_exec /Signal-Desktop sed -r '/mock/d' -i package.json

podman_exec /Signal-Desktop npm install -g pnpm cross-env npm-run-all
podman_exec /Signal-Desktop pnpm install
podman_exec /Signal-Desktop rm -rf ts/test-mock
podman_exec /Signal-Desktop pnpm run generate

podman_exec /Signal-Desktop/sticker-creator pnpm install
podman_exec /Signal-Desktop/sticker-creator pnpm run build

podman_exec /Signal-Desktop pnpm run build:release --"$ARCHSPECIFICVARIABLESHORT" --linux

# copy .deb out of builder container
podman cp signal-desktop-"$VERSION":/Signal-Desktop/release/signal-desktop_"$VERSION"_"$ARCHSPECIFICVARIABLECOMMON".deb ~/signal-"$ARCHSPECIFICVARIABLECOMMON".deb

# nice to have if we run on self-hosted infra, but since the vm is wiped every github actions run, this just adds extra time.
# podman stop signal-desktop-"$VERSION"
# podman rm signal-desktop-"$VERSION"
