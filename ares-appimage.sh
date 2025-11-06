#!/bin/sh

set -ex
ARCH="$(uname -m)"
REPO="https://github.com/ares-emulator/ares"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"

# Determine to build nightly or stable
if [ "$1" = 'devel' ]; then
	echo "Making nightly build of ares..."
	export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|nightly|*$ARCH.AppImage.zsync"
	VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9)"
	git clone "$REPO"
else
	echo "Making stable build of ares..."
	export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
	wget "$GRON" -O ./gron.awk
	chmod +x ./gron.awk
	VERSION=$(wget https://api.github.com/repos/ares-emulator/ares/tags -O - \
		| ./gron.awk | awk -F'=|"' '/name/ {print $3; exit}')
	git clone --branch "$VERSION" --single-branch "$REPO" ./ares
fi

# BUILD ARES
(
	cd ./ares
	mkdir ./build
	cd ./build
	cmake .. -G Ninja \
		-W no-dev \
		-D CMAKE_BUILD_TYPE=Release    \
  		-D ENABLE_CCACHE=ON            \
		-D ARES_BUNDLE_SHADERS=ON      \
		-D ARES_BUILD_LOCAL=OFF        \
		-D CMAKE_INSTALL_PREFIX="/usr" \
  		-D ARES_BUILD_OFFICIAL=YES     \
		-D ARES_SKIP_DEPS=ON           \
		--fresh
	cmake --build . -j"$(nproc)"
	cmake --install .
 	ccache -s -v
)
rm -rf ./ares
[ -n "$VERSION" ] && echo "$VERSION" > ~/version

# NOW MAKE APPIMAGE
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
export OUTPUT_APPIMAGE=1
export ADD_HOOKS="self-updater.bg.hook"
export OUTNAME=ares-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/ares.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/ares.png
export DEPLOY_OPENGL=1 
export DEPLOY_PIPEWIRE=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/ares /usr/bin/sourcery

mkdir -p ./dist
mv -v ./*.AppImage* ./dist

echo "All Done!"
