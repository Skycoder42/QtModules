#!/bin/sh
# $1 Qt Version
# $2 repoid
# $3 version
# $4+ skip packages
set -e

qtVer=$1
repoId=$2
version=$3
skip=$4

# get the repogen script
git clone "https://github.com/${repoId}" --branch "$version"
mv "./${repoId}/repogen.sh" ./
rm -rf "./${repoId}"

#prepare dirs
mkdir -p "$qtVer"
mkdir -p archives

pushd archives
#download all possible packages (.tar.xz)
for arch in android_armv7 android_x86 clang_64 doc gcc_64 ios; do
	if [ "$skip" != *"$arch"* ]; then
		file=build_${arch}_${qtDir}.tar.xz
		wget "https://github.com/${repoId}/releases/download/${version}/$file"
		tar -xf "$file" -C "../$qtVer/"
	fi
done

#download all possible packages (.zip)
for arch in mingw53_32 msvc2015 msvc2015_64 msvc2017_64 winrt_armv7_msvc2017 winrt_x64_msvc2017 winrt_x86_msvc2017; do
	if [ "$skip" != *"$arch"* ]; then
		file=build_${arch}_${qtDir}.zip
		wget "https://github.com/${repoId}/releases/download/${version}/$file"
		unzip -qq "$file" -d "../$qtVer/"
	fi
done
popd

./repogen.sh "$qtVer" "$version"
