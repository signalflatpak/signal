# RingRTC Builder

## UNMAINTAINED
This builder is unmaintained as Signal are now building/distributing RingRTC.
It should continue to work, but no updates will be provided (unless those builds start failing).

## Usage
1. Run `./setup.sh`. This will prompt for root privileges to install build dependancies.
2. Source .cargo/env to set up rust
3. Run `./ringrtc-builder.sh`.
4. It will build then copy the output file `libringrtc-arm64.node` or `libringrtc-amd64.node` into the main `signal-desktop-builder` directory.

NOTE: if you see an error about a "Missing sysroot", run the following python script:
`ringrtc/src/webrtc/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm64`
or
`ringrtc/src/webrtc/src/build/linux/sysroot_scripts/install-sysroot.py --arch=amd64`
