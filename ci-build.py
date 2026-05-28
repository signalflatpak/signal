#!/usr/bin/env python3

import argparse
import sys
import subprocess
import shutil


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


def container_exec(dir, cmd, version):
    ccmd = f"podman exec -it -w {dir} signal-desktop-{version} {cmd}"
    if not shutil.which("podman") and shutil.which("docker"):
        ccmd = f"docker exec -it -w {dir} signal-desktop-{version} {cmd}"
    print(f"$ {ccmd}")
    runcmd(ccmd)


def create_container(version, archcommon):
    create = f"--name=signal-desktop-{version} -it ghcr.io/signalflatpak/debbuilder:latest bash"
    start = f"start signal-desktop-{version}"
    if shutil.which("podman"):
        runcmd(f"podman create --arch {archcommon} {create}")
        runcmd(f"podman {start}")
    elif shutil.which("docker"):
        runcmd(f"docker create {create}")
        runcmd(f"docker {start}")


def copy_stop_move(version, archcommon):
    copy = f"cp signal-desktop-{version}:/Signal-Desktop/release/signal-desktop_{version}_{archcommon}.deb ~/signal-{archcommon}.deb"
    stop = f"stop signal-desktop-{version}"
    move = f"rm signal-desktop-{version}"
    if shutil.which("podman"):
        runcmd(f"podman {copy}")
        runcmd(f"podman {stop}")
        runcmd(f"podman {move}")
    elif shutil.which("docker"):
        runcmd(f"docker {copy}")
        runcmd(f"docker {stop}")
        runcmd(f"docker {move}")


def __main__():
    args = get_args()
    archcommon = "amd64" if args.arch == "amd64" else "arm64" if args.arch == "arm64" else None
    archshort = "x64" if args.arch == "amd64" else "arm64" if args.arch == "arm64" else None

    if archcommon is None or archshort is None:
        print(f"Arch is wrong: {args.arch} should be amd64 or arm64")
        sys.exit(1)

    create_container(args.version, archcommon)

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
            "cmd": f"pnpm run build:release --{archshort} --linux deb"
        },
    ]
    for p in podman_cmds:
        container_exec(p["dir"], p["cmd"], args.version)

    # copy deb, stop and remove container
    copy_stop_move(args.version, archcommon)


if __name__ == "__main__":
    __main__()
    sys.exit(0)
