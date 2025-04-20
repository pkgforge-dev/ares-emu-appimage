#!/bin/sh

set -ex

sed -i 's/DownloadUser/#DownloadUser/g' /etc/pacman.conf

if [ "$(uname -m)" = 'x86_64' ]; then
	PKG_TYPE='x86_64.pkg.tar.zst'
else
	PKG_TYPE='aarch64.pkg.tar.xz'
fi

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	alsa-lib \
	base-devel \
	cairo \
	cmake \
	curl \
	desktop-file-utils \
	gcc-libs \
	gdk-pixbuf2 \
	git \
	glib2 \
	glibc \
	gtk3 \
	hicolor-icon-theme \
	libao \
	libdecor \
	libgl \
	libpulse \
	librashader \
	libretro-shaders \
	libx11 \
	libxrandr \
	libxss \
	mesa \
	ninja \
	openal \
	pango \
	patchelf \
	pipewire-audio \
	pkgconf \
	pulseaudio \
	pulseaudio-alsa \
	sdl2 \
	strace \
	vulkan-driver \
	vulkan-icd-loader \
	wget \
	xorg-server-xvfb \
	zlib \
	zsync

# Make librashader
echo "Making extra dependencies..."
echo "---------------------------------------------------------------"
git clone "https://aur.archlinux.org/librashader.git" ./libreshader
( cd ./libreshader
  makepkg -f
  ls -la .
  pacman --noconfirm -U *.pkg.tar.*
)

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL" -O   ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL" -O   ./opus-nano.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
