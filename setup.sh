#!/bin/sh

set -e

export ARCH="$(uname -m)"

ZIG_VERSION="0.13.0"
PANDOC_VERSION="3.6.3"
MINISIGN_VERSION="0.11"

PANDOC_BASE="https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}"
MINISIGN_URL="https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz"
APPIMAGE_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"

case "${ARCH}" in
"x86_64")
	PANDOC_URL="${PANDOC_BASE}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz"
	;;
"aarch64")
	PANDOC_URL="${PANDOC_BASE}/pandoc-${PANDOC_VERSION}-linux-arm64.tar.gz"
	;;
*)
	echo "Unsupported ARCH: '${ARCH}'"
	exit 1
	;;
esac

rm -rf "/usr/share/libalpm/hooks/package-cleanup.hook"

# Update & install OS base dependencies
buildPkgs="base-devel freetype2 oniguruma wget mesa file zsync appstream xorg-server-xvfb patchelf binutils"
ghosttyPkgs="gtk4 libadwaita"
pacman -Syu --noconfirm
pacman -Syw --noconfirm ${buildPkgs} ${ghosttyPkgs}
pacman -Syq --needed --noconfirm ${buildPkgs} ${ghosttyPkgs}

# Download & install other dependencies
# appimagetool: https://github.com/AppImage/appimagetool
if [ ! -f '/usr/local/bin/appimagetool' ]; then
	wget -q "${APPIMAGE_URL}" -O /tmp/appimagetool.AppImage
	chmod +x /tmp/appimagetool.AppImage
	mv /tmp/appimagetool.AppImage /usr/local/bin/appimagetool
fi

# minisign: https://github.com/jedisct1/minisign
if [ ! -f '/usr/local/bin/minisign' ]; then
	wget -q "${MINISIGN_URL}" -O /tmp/minisign-linux.tar.gz
	tar -xzf /tmp/minisign-linux.tar.gz -C /tmp
	mv /tmp/minisign-linux/"${ARCH}"/minisign /usr/local/bin
fi

# zig: https://ziglang.org
if [ ! -d "/opt/zig-linux-${ARCH}-${ZIG_VERSION}" ]; then
	wget -q "${ZIG_URL}" -O /tmp/zig-linux.tar.xz
	tar -xf /tmp/zig-linux.tar.xz -C /opt
	ln -s "/opt/zig-linux-${ARCH}-${ZIG_VERSION}/zig" /usr/local/bin/zig
fi

# pandoc: https://github.com/jgm/pandoc
if [ ! -f '/usr/local/bin/pandoc' ]; then
	wget -q "${PANDOC_URL}" -O /tmp/pandoc-linux.tar.gz
	tar -xzf /tmp/pandoc-linux.tar.gz -C /tmp
	mv /tmp/"pandoc-${PANDOC_VERSION}"/bin/* /usr/local/bin
fi

# Cleanup
rm -rf \
	/tmp/appimagetool.AppImage \
	/tmp/minisign-linux* \
	/tmp/zig-linux.tar.xz \
	/tmp/pandoc*
