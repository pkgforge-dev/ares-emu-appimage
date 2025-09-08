#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel         \
	cmake              \
	ccache             \
	curl               \
	gcc-libs           \
	git                \
	gtk3               \
	libao              \
	libdecor           \
	libpulse           \
	libretro-shaders   \
	libx11             \
	libxrandr          \
	libxss             \
	ninja              \
	openal             \
	pipewire-audio     \
	pkgconf            \
	pulseaudio         \
	pulseaudio-alsa    \
	rust               \
	sdl3               \
	wget               \
	xorg-server-xvfb   \
	zlib               \
	zsync


echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-opengl gtk3-mini opus-mini libxml2-mini

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
  makepkg -fs --noconfirm
  sccache --show-stats
  ls -la .
  pacman --noconfirm -U *.pkg.tar.*
)

echo "All done!"
echo "---------------------------------------------------------------"
