#!/bin/sh

set -e

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

GHOSTTY_VERSION="$(cat VERSION)"
TMP_DIR="/tmp/ghostty-build"
APP_DIR="${TMP_DIR}/ghostty.AppDir"
PUB_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
UPINFO="gh-releases-zsync|$(echo "${GITHUB_REPOSITORY:-no-user/no-repo}" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
APPDATA_FILE="${PWD}/assets/ghostty.appdata.xml"
DESKTOP_FILE="${PWD}/assets/ghostty.desktop"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

rm -rf "${TMP_DIR}"

mkdir -p -- "${TMP_DIR}" "${APP_DIR}/usr" "${APP_DIR}/usr/lib" "${APP_DIR}/usr/share/metainfo"

cd "${TMP_DIR}"

wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz"
wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

minisign -V -m "ghostty-${GHOSTTY_VERSION}.tar.gz" -P "${PUB_KEY}" -s "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

rm "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

tar -xzmf "ghostty-${GHOSTTY_VERSION}.tar.gz"

rm "ghostty-${GHOSTTY_VERSION}.tar.gz"

cd "${TMP_DIR}/ghostty-${GHOSTTY_VERSION}"

sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' src/build/SharedDeps.zig

# Fetch Zig Cache
ZIG_GLOBAL_CACHE_DIR=/tmp/offline-cache ./nix/build-support/fetch-zig-cache.sh

# Build Ghostty with zig
zig build \
	--summary all \
	--prefix "${APP_DIR}/usr" \
	--system /tmp/offline-cache/p \
	-Doptimize=ReleaseFast \
	-Dcpu=baseline \
	-Dpie=true \
	-Demit-docs \
	-Dversion-string="${GHOSTTY_VERSION}"

cd "${APP_DIR}"

# bundle all libs
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k ./usr/bin/ghostty
rm -rf ./usr/bin

# Prepare AppImage -- Configure launcher script, metainfo and desktop file with icon.
echo 'unset ARGV0' > ./.env
echo 'GHOSTTY_RESOURCES_DIR=${SHARUN_DIR}/usr/share/ghostty' >> ./.env
ln -s ./bin/ghostty ./AppRun
./sharun -g

export VERSION="$(./AppRun --version | awk 'FNR==1 {print $2}')"
if [ -z "$VERSION" ]; then
	echo "ERROR: Could not get version from ghostty binary"
	VERSION=failed
#	exit 1
fi

cp "${APPDATA_FILE}" "usr/share/metainfo/com.mitchellh.ghostty.appdata.xml"

# Fix Gnome dock issues -- StartupWMClass attribute needs to be present.
cp "${DESKTOP_FILE}" "usr/share/applications/com.mitchellh.ghostty.desktop"
# WezTerm has this, it might be useful.
ln -s "com.mitchellh.ghostty.desktop" "usr/share/applications/ghostty.desktop"

ln -s "usr/share/applications/com.mitchellh.ghostty.desktop" .
ln -s "usr/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" .

cd "${TMP_DIR}"

# create app image
appimagetool -u "${UPINFO}" "${APP_DIR}"
