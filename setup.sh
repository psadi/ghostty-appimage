#!/bin/sh

set -e

export ARCH="$(uname -m)"

ZIG_VERSION="0.13.0"
PANDOC_VERSION="3.6.3"
MINISIGN_VERSION="0.11"
SHARUN_VERSION="v0.3.9"

GITHUB_BASE="https://github.com"
PANDOC_BASE="${GITHUB_BASE}/jgm/pandoc/releases/download/${PANDOC_VERSION}"
MINISIGN_URL="${GITHUB_BASE}/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz"
APPIMAGE_URL="${GITHUB_BASE}/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
LLVM_BASE="${GITHUB_BASE}/pkgforge-dev/llvm-libs-debloated/releases/download/continuous"
ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"
LIB4BIN_URL="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
SHARUN_URL="${GITHUB_BASE}/VHSgunzo/sharun/releases/download/${SHARUN_VERSION}/sharun-${ARCH}"
URUNTIME_URL="${GITHUB_BASE}/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-lite-${ARCH}"

case "${ARCH}" in
"x86_64")
	PANDOC_URL="${PANDOC_BASE}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz"
	LLVM_URL="${LLVM_BASE}/llvm-libs-nano-x86_64.pkg.tar.zst"
	LIBXML_URL="${LLVM_BASE}/libxml2-iculess-x86_64.pkg.tar.zst"
	;;
"aarch64")
	PANDOC_URL="${PANDOC_BASE}/pandoc-${PANDOC_VERSION}-linux-arm64.tar.gz"
	LLVM_URL="${LLVM_BASE}/llvm-libs-nano-aarch64.pkg.tar.xz"
	LIBXML_URL="${LLVM_BASE}/libxml2-iculess-aarch64.pkg.tar.xz"
	;;
*)
	echo "Unsupported ARCH: '${ARCH}'"
	exit 1
	;;
esac

# Update & install OS base dependencies
buildDeps="base-devel freetype2 oniguruma wget mesa file zsync appstream xorg-server-xvfb patchelf binutils strace git blueprint-compiler"
ghosttyDeps="gtk4 libadwaita"
pacman -Syuq --needed --noconfirm --noprogressbar ${buildDeps} ${ghosttyDeps}
pacman -Scc --noconfirm

# Debloated llvm and libxml2 without libicudata
wget "${LLVM_URL}" -O /tmp/llvm-libs.pkg.tar.zst
wget "${LIBXML_URL}" -O /tmp/libxml2.pkg.tar.zst
pacman -U --noconfirm /tmp/llvm-libs.pkg.tar.zst /tmp/libxml2.pkg.tar.zst

# Download & install other dependencies
# appimagetool: https://github.com/AppImage/appimagetool
if [ ! -f '/usr/local/bin/appimagetool' ]; then
	wget "${APPIMAGE_URL}" -O /tmp/appimagetool.AppImage
	chmod +x /tmp/appimagetool.AppImage
	mv /tmp/appimagetool.AppImage /usr/local/bin/appimagetool
fi

# minisign: https://github.com/jedisct1/minisign
if [ ! -f '/usr/local/bin/minisign' ]; then
	wget "${MINISIGN_URL}" -O /tmp/minisign-linux.tar.gz
	tar -xzf /tmp/minisign-linux.tar.gz -C /tmp
	mv /tmp/minisign-linux/"${ARCH}"/minisign /usr/local/bin
fi

# zig: https://ziglang.org
if [ ! -d "/opt/zig-linux-${ARCH}-${ZIG_VERSION}" ]; then
	wget "${ZIG_URL}" -O /tmp/zig-linux.tar.xz
	tar -xf /tmp/zig-linux.tar.xz -C /opt
	ln -s "/opt/zig-linux-${ARCH}-${ZIG_VERSION}/zig" /usr/local/bin/zig
fi

# pandoc: https://github.com/jgm/pandoc
if [ ! -f '/usr/local/bin/pandoc' ]; then
	wget "${PANDOC_URL}" -O /tmp/pandoc-linux.tar.gz
	tar -xzf /tmp/pandoc-linux.tar.gz -C /tmp
	mv /tmp/"pandoc-${PANDOC_VERSION}"/bin/* /usr/local/bin
fi

if [ ! -f '/usr/local/bin/lib4bin' ]; then
	wget "${LIB4BIN_URL}" -O /usr/local/bin/lib4bin
	chmod +x /usr/local/bin/lib4bin
fi

if [ ! -f '/usr/local/bin/sharun' ]; then
	wget "${SHARUN_URL}" -O /usr/local/bin/sharun
	chmod +x /usr/local/bin/sharun
fi

if [ ! -f '/usr/local/bin/uruntime' ]; then
	wget "${URUNTIME_URL}" -O /tmp/uruntime
	chmod +x /tmp/uruntime
	mv /tmp/uruntime /usr/local/bin/uruntime
fi

if [ ! -f '/opt/path-mapping.so' ]; then
	git clone https://github.com/fritzw/ld-preload-open.git
	(
		cd ld-preload-open
		make all
		mv ./path-mapping.so ../
	)
	rm -rf ld-preload-open
	mv ./path-mapping.so /opt/path-mapping.so
fi

# Cleanup
rm -rf \
	/tmp/appimagetool.AppImage \
	/tmp/minisign-linux* \
	/tmp/zig-linux.tar.xz \
	/tmp/pandoc* \
	/tmp/llvm-libs.pkg.tar.zst \
	/tmp/libxml2.pkg.tar.zst
