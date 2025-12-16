#!/usr/bin/env python3
import http.client
import argparse
import json
import sys
import time
import subprocess

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
    json_data=None
    if beta:
        conn.request('GET',
                     '/repos/signalapp/signal-desktop/releases',
                     headers=headers)
        response = conn.getresponse()
        jr = json.loads(response.read().decode("utf-8"))
        json_data=jr[0]
    else:
        conn.request('GET',
                     '/repos/signalapp/signal-desktop/releases/latest',
                     headers=headers)
        response = conn.getresponse()
        jr = json.loads(response.read().decode("utf-8"))
        json_data=jr
    conn.close()
    new_ver = json_data.get('tag_name')
    if SIGNAL_VERSION == new_ver:
        print("no new version")
        #sys.exit(0)
    else:
        expr = f"sed -e 's/{SIGNAL_VERSION}/{new_ver}/' -i {sys.argv[0]}"
        print(expr)

    version = new_ver[1:]
    v_arr = version.split('.')
    branch = f"{v_arr[0]}.{v_arr[1]}.x"
    print(f"V {version} Branch {branch}")
    if branch is None or version is None:
        print(f"Bad branch or version: branch '{branch}' version '{version}'")
        sys.exit(1)
    return version, branch


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


def main():
    version, branch = get_signal_version(args.beta)
    node_ver = node_check(branch)
    print("signal:", version, branch)
    print("node:", node_ver)


if __name__ == "__main__":
    main()
