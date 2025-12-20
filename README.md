# Signal Desktop Builder
This project allows building a Flatpak which provides Signal Desktop for ARM64 and AMD64.

This repository is a fork of [undef1/signal-desktop-builder](https://gitlab.com/undef1/signal-desktop-builder)

## Installing from the flatpak repository

For directions on installing the flatpak, seek [here](https://signalflatpak.github.io/signal).

## Installing via .flatpak bundle

- This repo provides .flatpak binaries as release artifacts [here](https://github.com/signalflatpak/signal/releases)
- The upstream repo provides .deb binaries [here](https://gitlab.com/undef1/signal-desktop-builder/-/packages) for some releases.

# Building this yourself

Github actions runs the following files:

- `.github/workflows/version_check.yml` is run daily to check for an updated upstream tag. If a new version is found, then a few files have a version variable replaced, the changes are committed, and a tag is pushed, and this triggers the second action.
- `.github/workflows/build.yml` creates a release, builds the Flatpak bundle files, and builds the Flatpak repo. The Flatpak repo folder is pushed to the github pages branch of this repo, creating an auto updating Flatpak repository.

To build by hand, you will need a Debian-based server.

## Installing dependencies

This needs to be done every time on CI, but only once on a self-hosted system. You can use docker instead of podman but will need to modify the scripts or set aliases yourself.

```
sudo apt install -qq bash rsync podman flatpak elfutils coreutils slirp4netns rootlesskit binfmt-support fuse-overlayfs flatpak-builder qemu-user-static
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```
```
sudo flatpak install --noninteractive --arch=[x86_64/aarch64] flathub org.electronjs.Electron2.BaseApp//24.08 org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08 -y
```

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

Build the Flatpak:

```
git clone https://github.com/signalflatpak/signal.git
cd signal
bash autobuild.sh
export VERSION="7.83.0"
bash ci-build.sh [arm64/amd64]
mv ~/Signal-Desktop_[arm64/amd64] Signal-Desktop_[arm64/amd64]
flatpak-builder --arch=[x86_64/aarch64] --gpg-sign=FBEF43DC8C6BE9A7 --repo=/opt/pakrepo --force-clean .builddir flatpak.yml
```

If cross-compiling, the build can take over an hour on a powerful machine.

Now you have your `.flatpakrepo` file and your `./repodir`. You can put those on a web server and tell people about them, or use them yourself.

If you just want to build a standalone .flatpak bundle that you can install anywhere, instead of building a repo:

`flatpak build-bundle --arch=[x86_64/aarch64] ./repodir ./signal.flatpak org.signal.Signal master`

# See also:

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

## Warranty / Fitness for Purpose

As with most Free Software there is no warranty. We're not responsible if this flatpak deletes your data or releases the magic smoke from your computer.

## Donations

I'll gladly accept donations but you're of course not obligated. This is a project I use myself and will continue as long as I still use it.
