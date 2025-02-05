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

# Update & install OS base dependencies
rm /etc/apt/apt.conf.d/docker-clean
buildPkgs="apt-utils build-essential libonig-dev libbz2-dev pandoc wget fuse libfuse2t64 file zsync appstream"
ghosttyPkgs="libgtk-4-dev libadwaita-1-dev"
apt-get -qq update && apt-get -qq -y upgrade
apt-get -qq -y --download-only install ${buildPkgs} ${ghosttyPkgs}
apt -qq -y install ${buildPkgs} ${ghosttyPkgs}

# Download & install other dependencies
# appimagetool: https://github.com/AppImage/appimagetool
if [ ! -f '/usr/local/bin/appimagetool' ]; then
	wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage" -O /tmp/appimagetool.AppImage
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
	wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz" -O /tmp/zig-linux.tar.xz
	tar -xf /tmp/zig-linux.tar.xz -C /opt
	ln -s "/opt/zig-linux-${ARCH}-${ZIG_VERSION}/zig" /usr/local/bin/zig
fi

# Cleanup
rm -rf \
	/tmp/appimagetool.AppImage \
	/tmp/minisign-linux.tar.gz \
	/tmp/minisign-linux \
	/tmp/zig-linux.tar.xz

# Reset DEBIAN_FRONTEND to default
unset DEBIAN_FRONTEND
