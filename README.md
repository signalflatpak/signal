# Signal Desktop Builder
This project allows building Signal Desktop for Debian 12 on ARM64 and AMD64.
It is currently a work in progress, with the goal of building a flatpak
which provides Signal Desktop.

This repository is a fork of [undef1/signal-desktop-builder](https://gitlab.com/undef1/signal-desktop-builder)

## Installing my Flatpak build

For directions on installing the flatpak, seek [here](https://signalflatpak.github.io/signal).

## Installing via .deb or .flatpak bundle

- The upstream repo provides .deb binaries [here](https://gitlab.com/undef1/signal-desktop-builder/-/packages) for some releases.
- This repo provides .deb and .flatpak binaries as release artifacts [here](https://github.com/signalflatpak/signal/releases)

## Building Signal

The process works through CI fairly well. I've included all the files in this repository for each of the CI platforms I've made it work on.

- `.build.yml` will work for [sourcehut builds](https://builds.sr.ht). The 3 secrets are a GPG key, SSH key, and SSH config. Sourcehut helpfully lets you specify secrets of this type and will put them in the appropriate places on your builder.
- `.github/workflows/build.yml` is for [github](https://github.com) actions. You will need the secrets I specified by name in the build manifest.
- `.gitlab-ci.yml` is obviously for [gitlab](https://gitlab.com) ci but is kind of incomplete, since I ran it on a self-hosted runner. This one you'll need to figure out yourself.

The builds take hours when cross-compiling and frequently time out in github's shared runners, but they take less time on a relatively powerful AMD or ARM server. [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/) will give you AMD or ARM servers for free. Yes, I know, it's Oracle, but this is genuinely the best way to build these. You can set one up as a self-hosted github/gitlab runner and it'll build the flatpak in 25 minutes.

To build by hand, you will need an Ubuntu or Debian server.

### Installing dependencies

This needs to be done every time on CI, but only once on a self-hosted system. You can use docker instead of podman but will need to modify the scripts or set aliases yourself.

```
sudo apt install -qq bash rsync podman flatpak elfutils coreutils slirp4netns rootlesskit binfmt-support fuse-overlayfs flatpak-builder qemu-user-static
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```
```
sudo flatpak install --noninteractive --arch=aarch64 flathub org.electronjs.Electron2.BaseApp//22.08 org.freedesktop.Platform//22.08 org.freedesktop.Sdk//22.08 -y
```
or
```
sudo flatpak install --noninteractive --arch=x86_64 flathub org.electronjs.Electron2.BaseApp//22.08 org.freedesktop.Platform//22.08 org.freedesktop.Sdk//22.08 -y
```

### Running Build Scripts

Fairly simple. `ci-build.sh` invokes `signal-buildscript.sh`, builds signal in an AMD or ARM docker container and copies the .deb out. It looks like there's some duplication of work between them; for historical reasons this was necessary because one of them would fail due to non-interactivity. I think if you run it by hand in tmux or something, you can comment out most of `ci-build.sh`.

First, though, run `./update-node.sh 6.12.x` where `6.12.x` is the name of the branch you are building. If you get a new nodejs version, update the Dockerfile's `ENV NODE_VERSION` line.

```
export VERSION="6.12.0"
bash ci-build.sh
podman stop signal-desktop-$VERSION
cp ~/signal-desktop.deb .
```
This build takes 2-3 hours.

If you just want the .deb, you now have it. Congrats.

## Building a Flatpak

Flatpak repos are just flat directories and a .flatpakrepo file.

You'll need a GPG key - if it's password protected you'll get asked for the password when building so you can't do that to a key you use in CI. To make one use `gpg --gen-key`. You don't have to give it your "real" info.

The flatpakrepo file looks like this:

```
[Flatpak Repo]
Title=Signal Flatpak Repo
Url=https://example.com/flatpak/signal-arm-repo/
GPGKey=<Key Data>
```

To get the key data, run `gpg --armor --export <key email or ID> > key.gpg`. 

Before you send that key anywhere, inspect `key.gpg` and make sure it begins and ends with `PGP PUBLIC KEY BLOCK` and __NOT__ `PGP PRIVATE KEY BLOCK`. Your private key should be kept private.

If you've made sure it's a public key, run `base64 --wrap=0 < key.gpg`. This is the key you put in `<Key Data>`.

For more info see [Flatpak.org's documentation on hosting a repo](https://docs.flatpak.org/en/latest/hosting-a-repository.html).

Get the Key ID of your secret key. You can get it in the GNOME application "Passwords and Keys" (or `seahorse`), or `gpg --list-keys --keyid-format long`.

Look for this line and that's the ID you supply to flatpak-builder.

```
pub   rsa4096/FBEF43DC8C6BE9A7 2022-06-04 [SC]
             |-- ^ this ID ---|
```

Build the flatpak:

```
flatpak-builder --arch=aarch64 --gpg-sign=<Key ID> --repo=./repodir --force-clean ./builddir flatpak.yml
```
or
```
flatpak-builder --arch=x86_64 --gpg-sign=<Key ID> --repo=./repodir --force-clean ./builddir flatpak.yml
```

Now you have your `.flatpakrepo` file and your `./repodir`. You can put those on a web server and tell people about them, or use them yourself.

If you just want to build a standalone .flatpak bundle that you can install anywhere, instead of building a repo:

`flatpak build-bundle --arch=aarch64 ./repodir ./signal.flatpak org.signal.Signal master`
or
`flatpak build-bundle --arch=x86_64 ./repodir ./signal.flatpak org.signal.Signal master`

## Github Actions notes:

to publish a new release:

- find latest stable tag from [upstream repo](https://github.com/signalapp/Signal-Desktop/releases)
- edit `Dockerfile` and set git clone to pull the correct branch (format is "5.45.x")
- run `update-node 5.45.x` to set Dockefile to use upstream's specified nodejs version
    - for '5.45.1' or other versions, you use the same '5.45.x' argument.
- update `org.signal.Signal.metainfo.xml` with the new version
- edit the build yml file (depending on which CI you're using) and set `VERSION` to new version
- push changes; this should trigger a new build

I also have create an `autobuild.sh` script to do all of this for you!

## See also:

https://gitlab.com/undef1/Snippets/-/snippets/2100495
https://gitlab.com/ohfp/pinebookpro-things/-/tree/master/signal-desktop
Flatpak based on [Flathub Sigal Desktop builds](https://github.com/flathub/org.signal.Signal/)
 - `signal-desktop.sh` https://github.com/flathub/org.signal.Signal/blob/master/signal-desktop.sh
 - `org.signal.Signal.metainfo.xml` https://github.com/flathub/org.signal.Signal/blob/master/org.signal.Signal.metainfo.xml
 - `flatpak.yml` https://github.com/flathub/org.signal.Signal/blob/master/org.signal.Signal.yaml

## Related projects:

- [Axolotl](https://github.com/nanu-c/axolotl)
- [Flare](https://gitlab.com/schmiddi-on-mobile/flare)

## Can these builds be trusted?

Only insofar as you can trust upstream Signal. There's almost nothing custom going on here. The builds you see in CI produce the artifacts on the release tag and automatically sync to the repo. There's nothing in between the two. You can decide from there.

This only exists because some people wanted Signal to work on the Pinephone, and it would take more work to _not_ make it a public thing. Plus this way I can get help from some awesome contributors.

So no, you can't trust these builds, you can't trust any software or anyone, but I can assure you at least I'm not trying to do anything weird here.

