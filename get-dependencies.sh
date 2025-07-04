#!/bin/sh

set -ex
ARCH="$(uname -m)"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	alsa-lib           \
	base-devel         \
	cmake              \
	ccache             \
	curl               \
	gcc-libs           \
	git                \
	glibc              \
	gtk3               \
	hicolor-icon-theme \
	libao              \
	libdecor           \
	libpulse           \
	libretro-shaders   \
	libx11             \
	libxrandr          \
	libxss             \
	mesa               \
	ninja              \
	openal             \
	pipewire-audio     \
	pkgconf            \
	pulseaudio         \
	pulseaudio-alsa    \
	rust               \
	sdl2               \
	sdl3               \
	vulkan-driver      \
	vulkan-icd-loader  \
	wget               \
	xorg-server-xvfb   \
	zlib               \
	zsync

case "$ARCH" in
	'x86_64')  PKG_TYPE='x86_64.pkg.tar.zst';;
	'aarch64') PKG_TYPE='aarch64.pkg.tar.xz';;
	''|*) echo "Unknown arch: $ARCH"; exit 1;;
esac

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-mini-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL" -O   ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL" -O   ./opus-nano.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

# Make librashader
echo "Making extra dependencies..."
echo "---------------------------------------------------------------"

# fix nonsense
sed -i 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
sed -i 's|-O2|-O3|; s|MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|; s|#MAKEFLAGS|MAKEFLAGS|' /etc/makepkg.conf
cat /etc/makepkg.conf

git clone "https://aur.archlinux.org/librashader.git" ./librashader
( cd ./librashader
  export RUSTC_WRAPPER="sccache"
  makepkg -f
  sccache --show-stats
  ls -la .
  pacman --noconfirm -U *.pkg.tar.*
)

echo "All done!"
echo "---------------------------------------------------------------"
