#!/bin/bash
set -x
echo "PATH: $PATH"

# Signal build requirements
echo "Entering /Signal-Desktop"
pushd /Signal-Desktop
git-lfs install
git config --global user.name name
git config --global user.email name@example.com
# The mock tests are broken on custom arm builds
sed -r '/mock/d' -i package.json
# Dry run
sed -r 's#("better-sqlite3": ").*"#\1file:../better-sqlite3"#' -i package.json
# This may have to be cancelled and run again to get it to actually rebuild deps...
# yarn install # not recommended by signal, but required due to those two sed lines.
# yarn install --frozen-lockfile
# rm -rf ts/test-mock # also broken on arm64
# yarn generate
# yarn build:webpack
# #yarn test always fails on arm...
# yarn build:release --arm64 --linux --dir
# yarn build:release --arm64 --linux deb
# popd
# 
# pushd /Signal-Desktop/release
# mv linux-arm64-unpacked signal
# tar cJvf signal-desktop_$(grep version ../package.json  | awk '{ print $2 }' | tr -d '",' | head -n 1).tar.xz signal

