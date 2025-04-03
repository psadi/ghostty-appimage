#!/bin/sh

set -eux

get_latest_gh_release() {

	local gh_ref="${1}"
	local version
	curl -s "https://api.github.com/repos/${gh_ref}/releases/latest" | jq -r .tag_name
}

# Update & install OS base dependencies
buildDeps="base-devel freetype2 oniguruma wget mesa file zsync appstream xorg-server-xvfb patchelf binutils strace git jq"
ghosttyDeps="gtk4 libadwaita gtk4-layer-shell"
rm -rf "/usr/share/libalpm/hooks/package-cleanup.hook"
pacman -Syuq --needed --noconfirm --noprogressbar ${buildDeps} ${ghosttyDeps}

export ARCH="$(uname -m)"

ZIG_VERSION="${ZIG_VERSION:-0.13.0}"
PANDOC_VERSION="$(get_latest_gh_release 'jgm/pandoc')"
MINISIGN_VERSION="$(get_latest_gh_release 'jedisct1/minisign')"
SHARUN_VERSION="$(get_latest_gh_release 'VHSgunzo/sharun')"
URUNTIME_VERSION="$(get_latest_gh_release 'VHSgunzo/uruntime')"

GITHUB_BASE="https://github.com"
PANDOC_BASE="${GITHUB_BASE}/jgm/pandoc/releases/download/${PANDOC_VERSION}"
MINISIGN_URL="${GITHUB_BASE}/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz"
URUNTIME_URL="${GITHUB_BASE}/VHSgunzo/uruntime/releases/download/${URUNTIME_VERSION}/uruntime-appimage-dwarfs-${ARCH}"
LLVM_BASE="${GITHUB_BASE}/pkgforge-dev/llvm-libs-debloated/releases/download/continuous"
ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"
SHARUN_URL="${GITHUB_BASE}/VHSgunzo/sharun/releases/download/${SHARUN_VERSION}/sharun-${ARCH}"
LD_PRELOAD_OPEN="${GITHUB_BASE}/fritzw/ld-preload-open.git"

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

# Debloated llvm and libxml2 without libicudata
wget "${LLVM_URL}" -O /tmp/llvm-libs.pkg.tar.zst
wget "${LIBXML_URL}" -O /tmp/libxml2.pkg.tar.zst
pacman -U --noconfirm /tmp/llvm-libs.pkg.tar.zst /tmp/libxml2.pkg.tar.zst

# Download & install other dependencies
# zig: https://ziglang.org
rm -rf /opt/zig*
unlink /usr/local/bin/zig || true
wget "${ZIG_URL}" -O /tmp/zig-linux.tar.xz
tar -xJf /tmp/zig-linux.tar.xz -C /opt
ln -s "/opt/zig-linux-${ARCH}-${ZIG_VERSION}/zig" /usr/local/bin/zig

# uruntime: https://github.com/VHSgunzo/uruntime
rm -rf /usr/local/bin/uruntime
wget "${URUNTIME_URL}" -O /tmp/uruntime
chmod +x /tmp/uruntime
mv /tmp/uruntime /usr/local/bin/uruntime

# minisign: https://github.com/jedisct1/minisign
rm -rf /usr/local/bin/minisign
wget "${MINISIGN_URL}" -O /tmp/minisign-linux.tar.gz
tar -xzf /tmp/minisign-linux.tar.gz -C /tmp
mv /tmp/minisign-linux/"${ARCH}"/minisign /usr/local/bin

# pandoc: https://github.com/jgm/pandoc
rm -rf /usr/local/bin/pandoc*
wget "${PANDOC_URL}" -O /tmp/pandoc-linux.tar.gz
tar -xzf /tmp/pandoc-linux.tar.gz -C /tmp
mv /tmp/"pandoc-${PANDOC_VERSION}"/bin/* /usr/local/bin

# sharun: https://github.com/VHSgunzo/sharun
rm -rf /usr/local/bin/sharun
wget "${SHARUN_URL}" -O /usr/local/bin/sharun
chmod +x /usr/local/bin/sharun

# ld-preload-open: https://github.com/fritzw/ld-preload-open
rm -rf /opt/path-mapping.so
git clone "${LD_PRELOAD_OPEN}"
(
	cd ld-preload-open
	make all
	mv ./path-mapping.so ../
)
rm -rf ld-preload-open
mv ./path-mapping.so /opt/path-mapping.so

# Cleanup
pacman -Scc --noconfirm

rm -rf \
	/tmp/appimagetool.AppImage \
	/tmp/minisign-linux* \
	/tmp/zig-linux.tar.xz \
	/tmp/pandoc* \
	/tmp/llvm-libs.pkg.tar.zst \
	/tmp/libxml2.pkg.tar.zst
