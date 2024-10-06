#!/bin/bash
echo "###ci-build.sh###"
set -x

if [ $1 == "amd64" ]; then
	ARCHSPECIFICVARIABLELONG="x86_64"
	ARCHSPECIFICVARIABLECOMMON="amd64"
	ARCHSPECIFICVARIABLESHORT="x64"
	ARCHSPECIFICVARIABLEVERSION="amd64"
fi

if [ $1 == "arm64" ]; then
	ARCHSPECIFICVARIABLELONG="aarch64"
	ARCHSPECIFICVARIABLECOMMON="arm64"
	ARCHSPECIFICVARIABLESHORT="arm64"
	ARCHSPECIFICVARIABLEVERSION="arm64v8"
fi

declare -a archspecific=("Dockerfile" "flatpak.yml")

for filename in ${archspecific[@]}; do
	sed -i "s/ARCHSPECIFICVARIABLELONG/$ARCHSPECIFICVARIABLELONG/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLECOMMON/$ARCHSPECIFICVARIABLECOMMON/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLESHORT/$ARCHSPECIFICVARIABLESHORT/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLEVERSION/$ARCHSPECIFICVARIABLEVERSION/g" "$filename"
done

if [ $2 == "flatpak" ]; then
	exit
fi

shopt -s localvar_inherit
podman build --jobs $(nproc) -t signal-desktop-image-$VERSION .
podman create --name=signal-desktop-$VERSION -it localhost/signal-desktop-image-$VERSION bash
podman start signal-desktop-$VERSION
##podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION bash -c "echo $PATH"
podman exec -it --env-file=env signal-desktop-$VERSION bash -i -c /signal-buildscript.sh
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION npm install --non-interactive
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION npm install --frozen-lockfile --non-interactive
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION rm -rf ts/test-mock
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION npm run generate
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION npm run build:release --$ARCHSPECIFICVARIABLESHORT --linux --dir
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION npm run build:release --$ARCHSPECIFICVARIABLESHORT --linux --deb

podman exec -it --env-file=env -w /Signal-Desktop/release signal-desktop-$VERSION mv linux-unpacked signal
podman exec -it --env-file=env -w /Signal-Desktop/release signal-desktop-$VERSION tar cJf signal-desktop_${VERSION}.tar.xz signal

podman exec -it --env-file=env signal-desktop-$VERSION ls -al /Signal-Desktop/release/
podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop_${VERSION}_${ARCHSPECIFICVARIABLECOMMON}.deb ~/signal-desktop.deb
podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop_${VERSION}.tar.xz ~/signal-desktop_${VERSION}.tar.xz

