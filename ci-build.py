#!/usr/bin/env python3

import argparse
import sys
import subprocess


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--arch", help="amd64/arm64")
    parser.add_argument("-b", "--branch", help="Signal Branch (v8.10.x)")
    parser.add_argument("-n", "--node", help="NodeJS version (v25.10.1)")
    parser.add_argument("-v", "--version", help="Signal version (v8.10.1)")
    args = parser.parse_args()
    if args.arch is None or args.branch is None or args.node is None or args.version is None:
        print("Provide all the arguments.")
        sys.exit(1)
    return args


def runcmd(cmd):
    output = subprocess.run(cmd, shell=True)
    if output.returncode != 0:
        print("error running", cmd, "\n", output.stdout, output.stderr)


def podman_exec(dir, cmd, version):
    cmd = f"podman exec -it -w {dir} signal-desktop-{version} {cmd}"
    runcmd(cmd)


def __main__():
    args = get_args()
    archcommon = "amd64" if args.arch == "amd64" else "arm64" if args.arch == "arm64" else None
    archshort = "x64" if args.arch == "amd64" else "arm64" if args.arch == "arm64" else None

    if archcommon is None or archshort is None:
        print(f"Arch is wrong: {args.arch} should be amd64 or arm64")
        sys.exit(1)

    runcmd(
        f"podman create --name=signal-desktop-{args.version} --arch {archcommon} -it ghcr.io/flatpaks/signalimage:latest bash"
    )
    runcmd(f"podman start signal-desktop-{args.version}")

    podman_cmds = [
        # clone
        {
            "dir": "/",
            "cmd": "git config --global user.name name"
        },
        {
            "dir": "/",
            "cmd": "git config --global user.email name@example.com"
        },
        {
            "dir":
            "/",
            "cmd":
            f"git clone -q https://github.com/signalapp/Signal-Desktop -b {args.branch}"
        },
        # download and set up node
        {
            "dir":
            "/opt",
            "cmd":
            f"wget -q https://nodejs.org/dist/{args.node}/node-{args.node}-linux-{archshort}.tar.gz"
        },
        {
            "dir": "/opt",
            "cmd": f"tar xf node-{args.node}-linux-{archshort}.tar.gz"
        },
        {
            "dir": "/opt",
            "cmd": f"mv node-{args.node}-linux-{archshort} node"
        },

        # build signal
        {
            "dir": "/Signal-Desktop",
            "cmd": "git-lfs install"
        },
        {
            "dir": "/Signal-Desktop",
            "cmd": "npm install -g pnpm cross-env npm-run-all"
        },
        {
            "dir": "/Signal-Desktop",
            "cmd": "pnpm install"
        },
        {
            "dir": "/Signal-Desktop",
            "cmd": "rm -rf ts/test-mock"
        },
        {
            "dir": "/Signal-Desktop",
            "cmd": "pnpm run generate"
        },

        # build sticker-creator
        {
            "dir": "/Signal-Desktop/sticker-creator",
            "cmd": "pnpm install"
        },
        {
            "dir": "/Signal-Desktop/sticker-creator",
            "cmd": "pnpm run build"
        },

        # build deb
        {
            "dir": "/Signal-Desktop",
            "cmd": f"pnpm run build:release --{archshort} --linux"
        },
    ]
    for p in podman_cmds:
        podman_exec(p["dir"], p["cmd"], args.version)

    # copy deb, stop and remove container
    runcmd(
        f"podman cp signal-desktop-{args.version}:/Signal-Desktop/release/signal-desktop_{args.version}_{archshort}.deb ~/signal-{archshort}.deb"
    )
    runcmd(f"podman stop signal-desktop-{args.version}")
    runcmd(f"podman rm signal-desktop-{args.version}")


if __name__ == "__main__":
    __main__()
    sys.exit(0)
