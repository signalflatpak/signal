#!/bin/bash
echo "###ci-build.sh###"
set -x
shopt -s localvar_inherit
podman build --jobs $(nproc) -t signal-desktop-image-$VERSION .
podman create --name=signal-desktop-$VERSION -it localhost/signal-desktop-image-$VERSION bash
podman start signal-desktop-$VERSION
##podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION bash -c "echo $PATH"
podman exec -it --env-file=env signal-desktop-$VERSION bash -i -c /signal-buildscript.sh
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn install --non-interactive
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn install --frozen-lockfile --non-interactive
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION rm -rf ts/test-mock
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn generate
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn build:webpack
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn build:release --ARCHSPECIFICVARIABLESHORT --linux --dir
podman exec -it --env-file=env -w /Signal-Desktop signal-desktop-$VERSION yarn build:release --ARCHSPECIFICVARIABLESHORT --linux deb

#podman exec -it --env-file=env -w /Signal-Desktop/release signal-desktop-$VERSION mv linux-unpacked signal
#podman exec -it --env-file=env -w /Signal-Desktop/release signal-desktop-$VERSION tar cJvf signal-desktop_${VERSION}.tar.xz signal

podman exec -it --env-file=env signal-desktop-$VERSION ls /Signal-Desktop/release/*.deb
podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop*.deb ~/signal-desktop.deb
#podman cp signal-desktop-${VERSION}:/Signal-Desktop/release/signal-desktop_${VERSION}.tar.xz ~/signal-desktop_${VERSION}.tar.xz

