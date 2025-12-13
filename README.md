# Signal Desktop Flatpak and .deb builds, from source, for arm64 and x86_64

This repository is a descended from [undef1/signal-desktop-builder](https://gitlab.com/undef1/signal-desktop-builder), credit where it's due.

## Installing from the flatpak repository

For directions on installing the flatpak, seek [here](https://flatpaks.github.io/signal).

## Installing via .flatpak bundle or .deb file

- This repo provides .flatpak binaries as release artifacts [here](https://github.com/flatpaks/signal/releases)
- This repo provides .deb binaries as release artifacts [here](https://github.com/flatpaks/signal/releases)
- The upstream repo provides .deb binaries [here](https://gitlab.com/undef1/signal-desktop-builder/-/packages) for some releases.

# Building this yourself

Brief overview:

- autobuild.sh finds the latest version of signalapp/signal-desktop from github's api. It modifies the .github/workflows/build.yml file and pushes a tag to this repo.
- .github/workflows/build.yml invokes the ci-build.sh script and flatpak-builder to produce a deb and bundle it into a flatpak binary.
- the flatpak repo dir is pushed to github pages.


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
git clone https://github.com/flatpaks/signal.git
cd signal
bash autobuild.sh
bash ci-build.sh -a [amd64/arm64] -n NODE_VERSION -v SIGNAL_VERSION -b BRANCH
mv ~/signal-[arm64/amd64].deb .
flatpak-builder --arch=[x86_64/aarch64] --gpg-sign=FBEF43DC8C6BE9A7 --repo=/opt/pakrepo --force-clean .builddir flatpak.yml
```

`.flatpakrepo` and your `./repodir` can be served over http.

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

## Issues are turned off

If you have something to contribute you can issue a PR. The discussions feature also exists and you can use that.

## Donations

I'll gladly accept donations but you're of course not obligated. This is a project I use myself and will continue as long as I still use it.

