#!/bin/bash
# arch-specific handler script
# Handles arch-specific files by copying them out of the archspecific directory and replacing the arch-specific variables in them to support both amd64/x86_64/x64 and arm64/aarch64 builds. Variables are replaced as follows:
# ARCHSPECIFICVARIABLELONG = x86_64/aarch64
# ARCHSPECIFICVARIABLECOMMON = amd64/arm64
# ARCHSPECIFICVARIABLESHORT = x64/arm64
# ARCHSPECIFICVARIABLEVERSION = amd64/arm64v8

cd "${0%/*}"

if [ $1 == "amd64" ]; then
	ARCHSPECIFICVARIABLELONG="x86_64"
	ARCHSPECIFICVARIABLECOMMON="amd64"
	ARCHSPECIFICVARIABLESHORT="x64"
	ARCHSPECIFICVARIABLEVERSION="amd64"
fi

if [ $1 == "arm64" ]; then
	ARCHSPECIFICVARIABLELONG="aarch64"
	ARCHSPECIFICVARIABLECOMMON="arm64"
	ARCHSPECIFICVARIABLESHORT="arm64"
	ARCHSPECIFICVARIABLEVERSION="arm64v8"
fi

for file in archspecific/*; do
	if [ -f $file ]; then
		filename="$(basename "$file")"
		cp "$file" "$filename"
		sed -i "s/ARCHSPECIFICVARIABLELONG/$ARCHSPECIFICVARIABLELONG/g" "$filename"
		sed -i "s/ARCHSPECIFICVARIABLECOMMON/$ARCHSPECIFICVARIABLECOMMON/g" "$filename"
		sed -i "s/ARCHSPECIFICVARIABLESHORT/$ARCHSPECIFICVARIABLESHORT/g" "$filename"
		sed -i "s/ARCHSPECIFICVARIABLEVERSION/$ARCHSPECIFICVARIABLEVERSION/g" "$filename"
	fi
done

for file in archspecific/*/*; do
	if [ -f $file ]; then
		filename="$(basename "$file")"
		directoryname="$(echo "$(dirname "$file")" | sed 's/.*\///')"
		cp "$file" "$directoryname"/"$filename"
		sed -i "s/ARCHSPECIFICVARIABLELONG/$ARCHSPECIFICVARIABLELONG/g" "$filename"
		sed -i "s/ARCHSPECIFICVARIABLECOMMON/$ARCHSPECIFICVARIABLECOMMON/g" "$directoryname"/"$filename"
		sed -i "s/ARCHSPECIFICVARIABLESHORT/$ARCHSPECIFICVARIABLESHORT/g" "$directoryname"/"$filename"
		sed -i "s/ARCHSPECIFICVARIABLEVERSION/$ARCHSPECIFICVARIABLEVERSION/g" "$directoryname"/"$filename"
	fi
done
