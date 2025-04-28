#!/bin/sh

set -eux

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

REPO="https://github.com/ares-emulator/ares"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD ARES
wget "$GRON" -O ./gron.awk
chmod +x ./gron.awk
VERSION=$(wget https://api.github.com/repos/ares-emulator/ares/tags -O - \
	| ./gron.awk | awk -F'=|"' '/name/ {print $3; exit}')
echo "$VERSION" > ~/version

git clone --branch "$VERSION" --single-branch "$REPO" ./ares && (
	cd ./ares

	# backport fix from aur package
	sed -i \
	  "s/virtual auto saveName() -> string { return pak->attribute(\"name\"); }/virtual auto saveName() -> string { return name(); }/g" \
	  ./mia/pak/pak.hpp

	mkdir ./build
	cd ./build
	cmake .. -G Ninja \
		-W no-dev \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX="/usr" \
		-D ARES_SKIP_DEPS=ON \
		--fresh
	cmake --build . -j"$(nproc)"
	cmake --install .
)
rm -rf ./ares

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/ares \
	/usr/bin/sourcery \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libXss.so* \
	/usr/lib/gtk-3*/*/* \
	/usr/lib/gio/modules/* \
	/usr/lib/gdk-pixbuf-*/*/*/* \
	/usr/lib/alsa-lib/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/*

cp -rv /usr/share/ares                                ./share
cp -v /usr/share/applications/ares.desktop            ./ares.desktop
cp -v /usr/share/icons/hicolor/256x256/apps/ares.png  ./ares.png
ln -s ./ares.png ./.DirIcon

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime \
	-i ./AppDir -o ares-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
