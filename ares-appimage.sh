#!/bin/sh

set -ex
ARCH="$(uname -m)"
REPO="https://github.com/ares-emulator/ares"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

# Determine to build nightly or stable
if [ "$1" = 'devel' ]; then
	echo "Making nightly build of ares..."
	UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|nightly|*$ARCH.AppImage.zsync"
	VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9)"
	git clone "$REPO"
else
	echo "Making stable build of ares..."
	UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
	wget "$GRON" -O ./gron.awk
	chmod +x ./gron.awk
	VERSION=$(wget https://api.github.com/repos/ares-emulator/ares/tags -O - \
		| ./gron.awk | awk -F'=|"' '/name/ {print $3; exit}')
	git clone --branch "$VERSION" --single-branch "$REPO" ./ares
fi

echo "$VERSION" > ~/version

# BUILD ARES
(
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
  		-D ENABLE_CCACHE=ON \
		-D CMAKE_INSTALL_PREFIX="/usr" \
		-D ARES_SKIP_DEPS=ON \
		--fresh
	cmake --build . -j"$(nproc)"
	cmake --install .
)
rm -rf ./ares

# NOW MAKE APPIMAGE
mkdir -p ./AppDir/share && (
	cd ./AppDir
	cp -rv /usr/share/ares                                ./share
	cp -v /usr/share/applications/ares.desktop            ./ares.desktop
	cp -v /usr/share/icons/hicolor/256x256/apps/ares.png  ./ares.png
	cp -v /usr/share/icons/hicolor/256x256/apps/ares.png  ./.DirIcon
	
	wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
	chmod +x ./sharun-aio
	xvfb-run -a -- \
		./sharun-aio l -p -v -e -s -k \
		/usr/bin/ares                 \
		/usr/bin/sourcery             \
		/usr/lib/lib*GL*.so*          \
		/usr/lib/dri/*                \
		/usr/lib/libXss.so*           \
		/usr/lib/gtk-3*/*/*           \
		/usr/lib/gio/modules/*        \
		/usr/lib/gdk-pixbuf-*/*/*/*   \
		/usr/lib/alsa-lib/*           \
		/usr/lib/pulseaudio/*         \
		/usr/lib/pipewire-0.3/*       \
		/usr/lib/spa-0.2/*/* || true # nobody saw a thing ok?
	rm -f ./sharun-aio
	
	# Prepare sharun
	ln ./sharun ./AppRun
	./sharun -g
	
	# Make intel video hardware accel work
	echo 'LIBVA_DRIVERS_PATH=${SHARUN_DIR}/shared/lib:${SHARUN_DIR}/shared/lib/dri' >> ./.env
)

# turn appdir into appimage
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime \
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-i ./AppDir                          \
	-o ./ares-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake ./*.AppImage -u ./*.AppImage

mkdir -p ./dist
mv -v ./*.AppImage* ./dist

echo "All Done!"
