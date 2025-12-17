#!/usr/bin/env python3
import http.client
import argparse
import json
import sys
import time
import subprocess
import datetime

SIGNAL_VERSION = 'v7.82.0'

parser = argparse.ArgumentParser()
parser.add_argument("-b",
                    "--beta",
                    help="Check for beta builds",
                    action="store_true")
parser.add_argument("-p",
                    "--push",
                    help="Push to git repo",
                    action="store_true")
args = parser.parse_args()


def get_signal_version(beta=False):
    # get latest version of signal from github api
    conn = http.client.HTTPSConnection('api.github.com')
    # user agent is required for github api
    headers = {
        "Accept": "application/json",
        "User-Agent": "flatpak-autobuilder"
    }
    json_data = None
    if beta:
        conn.request('GET',
                     '/repos/signalapp/signal-desktop/releases',
                     headers=headers)
        response = conn.getresponse()
        jr = json.loads(response.read().decode("utf-8"))
        json_data = jr[0]
    else:
        conn.request('GET',
                     '/repos/signalapp/signal-desktop/releases/latest',
                     headers=headers)
        response = conn.getresponse()
        jr = json.loads(response.read().decode("utf-8"))
        json_data = jr
    conn.close()
    new_ver = json_data.get('tag_name')

    version = new_ver[1:]
    v_arr = version.split('.')
    branch = f"{v_arr[0]}.{v_arr[1]}.x"
    print(f"V {version} Branch {branch}")
    if branch is None or version is None:
        print(f"Bad branch or version: branch '{branch}' version '{version}'")
        sys.exit(1)
    return new_ver, branch


def node_check(branch):
    conn = http.client.HTTPSConnection('raw.githubusercontent.com')
    # user agent is required for github api
    headers = {
        "Accept": "application/json",
        "User-Agent": "flatpak-autobuilder"
    }
    conn.request('GET',
                 f'signalapp/Signal-Desktop/{branch}/package.json',
                 headers=headers)
    response = conn.getresponse()
    jr = json.loads(response.read().decode("utf-8"))
    conn.close()
    node_ver = jr.get("engines").get("node")
    return node_ver


def update_files(signal_version, branch, node_version):
    now = datetime.datetime.now()
    timestr = now.isoformat().split("T")[0]
    ver = signal_version[1:]
    exprs = [
        f"sed -i 's/NODE_VERSION: .*/NODE_VERSION: \"v{node_version}\"/' .github/workflows/build.yml",
        f"sed -i 's/SIGNAL_VERSION: .*/SIGNAL_VERSION: \"{ver}\"/' .github/workflows/build.yml",
        f"sed -i 's/SIGNAL_BRANCH: .*/SIGNAL_BRANCH: \"{branch}\"/' .github/workflows/build.yml",
        f"sed -e 's,<release version.*,<release version=\"{ver}\" date=\"{timestr}\"/>,' -i org.signal.Signal.metainfo.xml",
        f"sed -e 's/{SIGNAL_VERSION}/v{signal_version}/' -i {sys.argv[0]}"
    ]
    for expr in exprs:
        print(expr)
        subprocess.run(expr, shell=True)


def commit(version, branch):
    status = 'git status | grep "nothing to commit, working tree clean"'
    r = subprocess.run(status, shell=True)
    if r.returncode > 0:
        exprs = [
            f'git commit -am "Autobuild {version} {branch}"',
            f'git tag {version}', 'git push -f --tags'
        ]
        for expr in exprs:
            subprocess.run(expr, shell=True)


def main():
    version, branch = get_signal_version(args.beta)
    node_ver = node_check(branch)
    print("signal:", version, branch)
    print("node:", node_ver)
    if version == SIGNAL_VERSION:
        print("no new version")
        sys.exit(0)
    update_files(version, branch, node_ver)
    if args.push:
        commit(version, branch)


if __name__ == "__main__":
    main()
