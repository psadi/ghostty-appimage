#!/bin/sh

set -e

export DEBIAN_FRONTEND="noninteractive"

ZIG_VERSION="0.13.0"

# update & install os base dependencies
buildPkgs="build-essential libonig-dev libbz2-dev pandoc wget fuse libfuse2t64 file zsync appstream"
ghosttyPkgs="libgtk-4-dev libadwaita-1-dev"
apt-get -qq update && apt-get -qq -y upgrade && apt-get -qq -y install ${buildPkgs} ${ghosttyPkgs}

# download & install other dependencies
# appimagetool: https://github.com/AppImage/appimagetool
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
install appimagetool-x86_64.AppImage /usr/local/bin/appimagetool

# minisign: https://github.com/jedisct1/minisign
wget -q "https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz"
tar -xzf minisign-0.11-linux.tar.gz
mv minisign-linux/x86_64/minisign /usr/local/bin

# zig: https://ziglang.org
wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz" -C /opt
ln -s "/opt/zig-linux-x86_64-${ZIG_VERSION}/zig" /usr/local/bin/zig

# cleanup
rm -r \
	"appimagetool-x86_64.AppImage" \
	"minisign-0.11-linux.tar.gz" \
	"minisign-linux" \
	"zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
