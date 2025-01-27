#!/bin/sh

set -e

export ARCH="$(uname -m)"
GHOSTTY_VERSION="1.0.1"
TMP_DIR="/tmp/ghostty-build"
APP_DIR="${TMP_DIR}/ghostty.AppDir"
PUB_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
UPINFO="gh-releases-zsync|$(echo "${GITHUB_REPOSITORY:-no-user/no-repo}" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
APPDATA_FILE="${PWD}/assets/ghostty.appdata.xml"
DESKTOP_FILE="${PWD}/assets/ghostty.desktop"

# Clean up and create directories
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}" "${APP_DIR}/usr/lib" "${APP_DIR}/usr/share/metainfo"

# Detect latest version if jq is available and 'latest' is requested
if command -v jq >/dev/null 2>&1 && [ "$1" = "latest" ]; then
	GHOSTTY_VERSION=$(curl -s https://api.github.com/repos/ghostty-org/ghostty/tags |
		jq -r '[.[] | select(.name != "tip") | .name | ltrimstr("v")] | sort_by(split(".") | map(tonumber)) | last')
fi

cd "${TMP_DIR}"

# Download and verify Ghostty
wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz"
wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"
minisign -V -m "ghostty-${GHOSTTY_VERSION}.tar.gz" -P "${PUB_KEY}" -s "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"
rm "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

# Extract and build Ghostty
tar -xzmf "ghostty-${GHOSTTY_VERSION}.tar.gz"
rm "ghostty-${GHOSTTY_VERSION}.tar.gz"
cd "ghostty-${GHOSTTY_VERSION}"

sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' build.zig

# Fetch Zig Cache
ZIG_GLOBAL_CACHE_DIR=/tmp/offline-cache ./nix/build-support/fetch-zig-cache.sh

# Build Ghostty with Zig
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

# Bundle all libraries
ldd ./usr/bin/ghostty | awk -F"[> ]" '/=>/ {print $3}' | xargs -I {} cp --update=none -v {} ./usr/lib

# Handle ld-linux based on architecture
case "${ARCH}" in
"x86_64") ld_linux="ld-linux-x86-64.so.2" ;;
"aarch64") ld_linux="ld-linux-aarch64.so.1" ;;
*)
	echo "Unsupported ARCH: '${ARCH}'"
	exit 1
	;;
esac

cp -v /usr/lib/${ARCH}-linux-gnu/libpthread.so.0 ./usr/lib
if ! mv ./usr/lib/${ld_linux} ./ld-linux.so; then
	cp -v /usr/lib/${ARCH}-linux-gnu/${ld_linux} ./ld-linux.so
fi

# Prepare AppImage
cat <<'EOF' >./AppRun
#!/usr/bin/env sh

HERE="$(dirname "$(readlink -f "$0")")"

export GHOSTTY_RESOURCES_DIR="${HERE}/usr/share/ghostty"

launch(){
  "${HERE}"/ld-linux.so --library-path "${HERE}"/usr/lib "${HERE}"/usr/bin/ghostty "$@"
}

launch "$@"
exit_code=$?

if [ "$exit_code" -gt 0 ] && [ -n "$WAYLAND_DISPLAY" ]; then
    export GDK_BACKEND=x11
    launch "$@"
fi
EOF

chmod +x AppRun

# Get version from Ghostty binary
VERSION=$(./AppRun --version 2>/dev/null | awk 'FNR==1 {print $2}')
if [ -z "$VERSION" ]; then
	echo "ERROR: Could not get version from ghostty binary"
	exit 1
fi

# Copy and link desktop and appdata files
cp "${APPDATA_FILE}" "usr/share/metainfo/com.mitchellh.ghostty.appdata.xml"
cp "${DESKTOP_FILE}" "usr/share/applications/com.mitchellh.ghostty.desktop"
ln -s "com.mitchellh.ghostty.desktop" "usr/share/applications/ghostty.desktop"
ln -s "usr/share/applications/com.mitchellh.ghostty.desktop" .
ln -s "usr/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" .

# Create AppImage
cd "${TMP_DIR}"
appimagetool -u "${UPINFO}" "${APP_DIR}"
