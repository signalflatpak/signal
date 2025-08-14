#!/usr/bin/env bash

SIGNAL_VERSION='v7.44.0'

usage() {
	echo ""
	echo "Options:"
	echo " -b - fetch beta build. Optional."
	echo " -p - push to git repo. Optional."
	echo " -h - display this help text."
	echo ""
}

PUSH='false'
BETA='false'

while getopts 'pbh' OPTION; do
	case "$OPTION" in
		p)
			PUSH='true'
			;;
		b)
			BETA='true'
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
	dep_packages="jq curl"
	sudo apt -qq install $dep_packages
}

# get latest non-beta release version from github API
latest_ver=$(curl -s https://api.github.com/repos/signalapp/signal-desktop/releases|jq -r '[.[] | select(.prerelease|not).tag_name][0]')

# if run with "./autobuild.sh -b" then it will not filter out prerelease
if [[ "$BETA" == "true" ]];then
	latest_ver=$(curl -s https://api.github.com/repos/signalapp/signal-desktop/releases|jq -r '[.[].tag_name][0]')
fi

# determine if a build needs to be done at all
if [[ "$latest_ver" == "$SIGNAL_VERSION" ]];then
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

sed -i "s/$SIGNAL_BRANCH/$latest_branch/" flatpak.yml
sed -i "s/$SIGNAL_BRANCH/$latest_branch/" .github/workflows/build.yml
sed -i "s/$SIGNAL_VERSION/$latest_version/g" .github/workflows/build.yml
sed -i "s/release version.*/release version=\"$latest_version\" date=\"$(date +%Y-%m-%d)\"\/>/" org.signal.Signal.metainfo.xml
sed -i "s/$SIGNAL_BRANCH/$latest_branch/" README.md

commit(){
	git commit -am "Autobuild for $version,branch $branch"
	git tag $version
	git push
	git push -f origin $version
}

if [[ "$PUSH" == "true" ]];then
	git status | grep "nothing to commit, working tree clean" || commit
fi
