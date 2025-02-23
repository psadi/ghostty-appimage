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
BUILD_ARGS="
	--summary all \
	--prefix ${APP_DIR} \
	-Doptimize=ReleaseFast \
	-Dcpu=baseline \
	-Dpie=true \
	-Demit-docs \
	-Dgtk-wayland=true \
	-Dgtk-x11=true"

rm -rf "${TMP_DIR}"

mkdir -p -- "${TMP_DIR}" "${APP_DIR}/share/metainfo" "${APP_DIR}/shared/lib"

cd "${TMP_DIR}"

if [ $GHOSTTY_VERSION == "tip" ]; then
	BUILD_DIR="ghostty-source"
	wget "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-source.tar.gz" -O ghostty-${GHOSTTY_VERSION}.tar.gz
	wget "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-source.tar.gz.minisig" -O ghostty-${GHOSTTY_VERSION}.tar.gz.minisig
else
	BUILD_DIR="ghostty-${GHOSTTY_VERSION}"
	BUILD_ARGS="${BUILD_ARGS} -Dversion-string=${GHOSTTY_VERSION}"
	wget "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz"
	wget "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"
fi

minisign -V -m "ghostty-${GHOSTTY_VERSION}.tar.gz" -P "${PUB_KEY}" -s "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

rm "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

tar -xzmf "ghostty-${GHOSTTY_VERSION}.tar.gz"

rm "ghostty-${GHOSTTY_VERSION}.tar.gz"

cd "${TMP_DIR}/${BUILD_DIR}"

# Fetch Zig Cache
# if [ -f './nix/build-support/fetch-zig-cache.sh' ]; then
# 	ZIG_GLOBAL_CACHE_DIR=/tmp/offline-cache ./nix/build-support/fetch-zig-cache.sh
# 	BUILD_ARGS="${BUILD_ARGS} --system /tmp/offline-cache/p"
# fi

# Build Ghostty with zig
echo " BUILD_ARGS: '${BUILD_ARGS}"
zig build ${BUILD_ARGS}

# Prepare AppImage -- Configure launcher script, metainfo and desktop file with icon.
cd "${APP_DIR}"

cp "${APPDATA_FILE}" "share/metainfo/com.mitchellh.ghostty.appdata.xml"
cp "${DESKTOP_FILE}" "share/applications/com.mitchellh.ghostty.desktop"

ln -s "com.mitchellh.ghostty.desktop" "share/applications/ghostty.desktop"
ln -s "share/applications/com.mitchellh.ghostty.desktop" .
ln -s "share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" .

# bundle all libs
xvfb-run -a -- lib4bin -p -v -e -s -k ./bin/ghostty /usr/lib/libEGL*

sleep 1

# preload libpixbufloader /w ld-preload-open as svg icons breaks
# either on ghostty tab bar or gnome-text-editor while config edit or both :(
mv ./shared/lib/gdk-pixbuf-2.0 ./
cp -rv /opt/path-mapping.so ./shared/lib/
cp -rv gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so ./shared/lib/

echo 'path-mapping.so' >./.preload

echo 'PATH_MAPPING=/usr/lib/gdk-pixbuf-2.0:${SHARUN_DIR}/gdk-pixbuf-2.0' >>./.env
echo 'GHOSTTY_RESOURCES_DIR=${SHARUN_DIR}/share/ghostty' >>./.env
echo 'unset ARGV0' >>./.env

ln -s ./bin/ghostty ./AppRun
./sharun -g

export VERSION="$(./AppRun --version | awk 'FNR==1 {print $2}')"
if [ -z "$VERSION" ]; then
	echo "ERROR: Could not get version from ghostty binary"
	exit 1
fi

cd "${TMP_DIR}"

# create app image
appimagetool -u "${UPINFO}" "${APP_DIR}"
