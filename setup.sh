#!/bin/sh

set -e

export DEBIAN_FRONTEND="noninteractive"
export ARCH="$(uname -m)"

ZIG_VERSION="0.13.0"
MINISIGN_URL="https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz"

# Detect latest version numbers when jq is available.
if command -v jq >/dev/null 2>&1; then
	if [ "$1" = "latest" ]; then
		ZIG_VERSION="$(
			curl -s "https://ziglang.org/download/index.json" |
				jq -r '[keys[] | select(. != "master" and contains("."))] | sort_by(split(".") | map(tonumber)) | last'
		)"
		MINISIGN_URL="$(
			curl -s "https://api.github.com/repos/jedisct1/minisign/releases/latest" |
				jq -r --arg prefix "minisign" --arg suffix "linux.tar.gz" \
					'.assets[] | select(.name | startswith($prefix) and endswith($suffix)) | .browser_download_url'
		)"
	fi
fi

# update & install os base dependencies
buildPkgs="build-essential libonig-dev libbz2-dev pandoc wget fuse libfuse2t64 file zsync appstream"
ghosttyPkgs="libgtk-4-dev libadwaita-1-dev"
apt-get -qq update && apt-get -qq -y upgrade && apt-get -qq -y install ${buildPkgs} ${ghosttyPkgs}

# download & install other dependencies
# appimagetool: https://github.com/AppImage/appimagetool
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
install "appimagetool-${ARCH}.AppImage" /usr/local/bin/appimagetool

# minisign: https://github.com/jedisct1/minisign
wget -q "${MINISIGN_URL}" -O "minisign-linux.tar.gz"
tar -xzf "minisign-linux.tar.gz"
mv minisign-linux/"${ARCH}"/minisign /usr/local/bin

# zig: https://ziglang.org
wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"
tar -xf "zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz" -C /opt
ln -s "/opt/zig-linux-${ARCH}-${ZIG_VERSION}/zig" /usr/local/bin/zig

# cleanup
rm -r \
	"appimagetool-${ARCH}.AppImage" \
	"minisign-linux.tar.gz" \
	"minisign-linux" \
	"zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz"
