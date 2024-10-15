#!/usr/bin/env bash

SIGNAL_VERSION='v7.28.0'

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

node_version=$(curl -s https://raw.githubusercontent.com/signalapp/Signal-Desktop/${branch}/package.json | jq -r .engines.node)
if [ ! "$(cat Dockerfile | grep NODE_VERSION= | sed 's/.*v//')" == "$node_version" ]; then
    sed -i "s:ENV NODE_VERSION=.*:ENV NODE_VERSION=v${node_version}:" Dockerfile
fi
# replace the clone line in Dockerfile with the new branch
sed -e "s,RUN git clone https://github.com/signalapp/Signal-Desktop.*$,RUN git clone https://github.com/signalapp/Signal-Desktop -b $branch," -i Dockerfile
# replace the VERSION variable in the CI manifests
sed -e "s,VERSION: .*$,VERSION: \"$version\"," -i .github/workflows/build.yml
sed -e "s,VERSION: .*$,VERSION: \"$version\"," -i .build.yml
sed -e "s,VERSION: .*$,VERSION: \"$version\"," -i .gitlab-ci.yml
dt=$(date +%Y-%m-%d)
sed -e "s,<release version.*,<release version=\"${latest_ver:1}\" date=\"$dt\"/>," -i org.signal.Signal.metainfo.xml

commit(){
	git commit -am "Autobuild for $version,branch $branch"
	git tag $version
	git push
	git push -f origin $version
}

if [[ "$PUSH" == "true" ]];then
	git status | grep "nothing to commit, working tree clean" || commit
fi

