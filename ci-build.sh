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
	git restore $filename
	sed -i "s/ARCHSPECIFICVARIABLELONG/$ARCHSPECIFICVARIABLELONG/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLECOMMON/$ARCHSPECIFICVARIABLECOMMON/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLESHORT/$ARCHSPECIFICVARIABLESHORT/g" "$filename"
	sed -i "s/ARCHSPECIFICVARIABLEVERSION/$ARCHSPECIFICVARIABLEVERSION/g" "$filename"
done

if [ $2 == "flatpak" ]; then
	exit
fi

ENV="PATH=/Signal-Desktop/node_modules/.bin:/root/.cargo/bin:/opt/node/bin:/root/.cargo/bin:/opt/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

shopt -s localvar_inherit
podman build --jobs $(nproc) -t signal-desktop-image-$VERSION .
podman create --name=signal-desktop-$VERSION -it localhost/signal-desktop-image-$VERSION bash
podman start signal-desktop-$VERSION
##podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION bash -c "echo $PATH"
podman exec -it --env="$ENV" signal-desktop-$VERSION pushd /Signal-Desktop
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION git-lfs install
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION git config --global user.name name
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION git config --global user.email name@example.com
# The mock tests are broken on custom arm builds
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION sed -r '/mock/d' -i package.json
# Dry run
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION sed -r 's#("better-sqlite3": ").*"#\1file:../better-sqlite3"#' -i package.json
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION npm install --non-interactive
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION npm install --frozen-lockfile --non-interactive
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION rm -rf ts/test-mock
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION npm run generate
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION npm run build:release --$ARCHSPECIFICVARIABLESHORT --linux --dir
podman exec -it --env="$ENV" -w /Signal-Desktop signal-desktop-$VERSION npm run build:release --$ARCHSPECIFICVARIABLESHORT --linux --deb

podman exec -it --env="$ENV" -w /Signal-Desktop/release signal-desktop-$VERSION mv linux-unpacked signal
#podman exec -it --env="$ENV" -w /Signal-Desktop/release signal-desktop-$VERSION tar cJf signal-desktop_${VERSION}.tar.xz signal

podman exec -it --env="$ENV" signal-desktop-$VERSION ls -al /Signal-Desktop/release/
podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop_${VERSION}_${ARCHSPECIFICVARIABLECOMMON}.deb ~/signal-desktop.deb
#podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop_${VERSION}.tar.xz ~/signal-desktop_${VERSION}.tar.xz

