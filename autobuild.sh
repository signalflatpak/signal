#!/bin/bash
echo "###autobuild.sh###"
set -x

SIGNAL_VERSION='v7.29.0'

usage() {
	echo ""
	echo "Options:"
	echo " -b - fetch beta build. Optional."
	echo " -p - push to git repo. Optional."
	echo " -f - Flatpak. Optional."
	echo " -h - display this help text."
	echo ""
}

PUSH='false'
BETA='false'
FLATPAK='false'

while getopts 'pbfh' OPTION; do
	case "$OPTION" in
		p)
			PUSH='true'
			;;
		b)
			BETA='true'
			;;
		f)
			FLATPAK='true'
			;;
		h)
			usage
			exit 0
			;;
		*)
			usage
			exit 1
			;;
	esac
done


deps(){
	if [[ ! -z "$(which flatpak-node-generator)" ]]; then
		dep_packages="jq curl flatpak-builder git"
	else
		dep_packages="jq curl"
	fi

	sudo apt -qq install $dep_packages
}

# get latest non-beta release version from github API
latest_ver=$(curl -s https://api.github.com/repos/signalapp/signal-desktop/releases|jq -r '[.[] | select(.prerelease|not).tag_name][0]')

# if run with "./autobuild.sh -b" then it will not filter out prerelease
if [[ "$BETA" == "true" ]];then
	latest_ver=$(curl -s https://api.github.com/repos/signalapp/signal-desktop/releases|jq -r '[.[].tag_name][0]')
fi

# determine if a build needs to be done at all
if [[ "$latest_ver" == "$SIGNAL_VERSION" ]] && [[ "$FLATPAK" == "false" ]];then
	exit 0
else
	sed -e "s/$SIGNAL_VERSION/$latest_ver/" -i $0
fi


# make it an array, starting after the 'v'
version="${latest_ver:1}"
readarray -d . -t vers <<< ${version}
# branch is major.minor.x
branch="${vers[0]}.${vers[1]}.x"

echo "V $version Branch $branch"

sleep 3

# run flatpak-node-generator
if [[ ! -z "$(which flatpak-node-generator)" ]]; then
	git clone https://github.com/signalapp/Signal-Desktop.git -b $branch
	cd Signal-Desktop
	flatpak-node-generator npm package-lock.json
	cp generated-sources.json ../
	cd ../
	rm -rf Signal-Desktop
fi

if [[ "$FLATPAK" == "true" ]]; then
	exit
fi

# replace the VERSION variable in the CI manifests
sed -e "s,VERSION: .*$,VERSION: \"$version\"," -i .github/workflows/build.yml
dt=$(date +%Y-%m-%d)
sed -e "s,<release version.*,<release version=\"${latest_ver:1}\" date=\"$dt\"/>," -i org.signal.Signal.metainfo.xml
sed -e "s,export VERSION=.*$,export VERSION=\"$version\"," -i README.md

commit(){
	git commit -am "Autobuild for $version,branch $branch"
	git tag $version
	git push
	git push -f origin $version
}

if [[ "$PUSH" == "true" ]];then
	git status | grep "nothing to commit, working tree clean" || commit
fi

