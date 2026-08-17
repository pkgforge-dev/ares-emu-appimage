#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	cmake                  \
	gcc-libs               \
	libao                  \
	libretro-shaders-slang \
	libx11                 \
	libxrandr              \
	libxss                 \
	ninja                  \
	openal                 \
	pkgconf                \
	rust                   \
	sdl3                   \
	zlib

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

# Comment this out if you need an AUR package
make-aur-package librashader

# If the application needs to be manually built that has to be done down here

echo "Building ares..."
echo "---------------------------------------------------------------"
git clone https://github.com/ares-emulator/ares ./ares && (
	cd ./ares

	# Determine to build nightly or stable
	if [ "${DEVEL_RELEASE-}" = 1 ]; then
		git rev-parse --short HEAD > ~/version
	else
		git fetch --tags origin
		TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha\|beta\|nightly' | head -1)
		git checkout "$TAG"
		echo "$TAG" > ~/version
	fi

	mkdir -p ./build
	cd ./build
	cmake ../ \
		-G Ninja                     \
		-W no-dev                    \
		-D CMAKE_BUILD_TYPE=Release  \
		-D ARES_BUNDLE_SHADERS=ON    \
		-D ARES_BUILD_LOCAL=OFF      \
		-D CMAKE_INSTALL_PREFIX=/usr \
		-D ARES_BUILD_OFFICIAL=YES   \
		-D ARES_SKIP_DEPS=ON         \
		--fresh
	cmake --build ./ -j"$(nproc)"
	cmake --install ./
)
