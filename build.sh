#!/bin/sh

set -e

GHOSTTY_VERSION="1.0.1"
TMP_DIR="/tmp/ghostty-build"
APP_DIR="${TMP_DIR}/ghostty.AppDir"
PUB_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

rm -rf "${TMP_DIR}"

mkdir -p -- "${TMP_DIR}" "${APP_DIR}/usr" "${APP_DIR}/usr/lib" "${APP_DIR}/usr/share/metainfo"

cd "${TMP_DIR}"

wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz"
wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

minisign -V -m "ghostty-${GHOSTTY_VERSION}.tar.gz" -P "${PUB_KEY}" -s "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

rm ghostty-${GHOSTTY_VERSION}.tar.gz.minisig

tar -xzmf "ghostty-${GHOSTTY_VERSION}.tar.gz"

rm "ghostty-${GHOSTTY_VERSION}.tar.gz"

cd "${TMP_DIR}/ghostty-${GHOSTTY_VERSION}"

sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' build.zig

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
ldd ./usr/bin/ghostty | awk -F"[> ]" '{print $4}' | xargs -I {} cp --update=none -v {} ./usr/lib
if ! mv ./usr/lib/ld-linux-x86-64.so.2 ./; then
	cp -v /lib64/ld-linux-x86-64.so.2 ./
fi

# prep appimage
cat <<'EOF' >./AppRun
#!/usr/bin/env sh

HERE="$(dirname "$(readlink -f "$0")")"

export TERM=xterm-256color
export GHOSTTY_RESOURCES_DIR="${HERE}/usr/share/ghostty"

exec "${HERE}"/ld-linux-x86-64.so.2 --library-path "${HERE}"/usr/lib "${HERE}"/usr/bin/ghostty "$@"
EOF

chmod +x AppRun

ln -s usr/share/applications/com.mitchellh.ghostty.desktop .
ln -s usr/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png .

sed -i 's/;TerminalEmulator;/;TerminalEmulator;Utility;/' com.mitchellh.ghostty.desktop

cat <<'EOF' >./usr/share/metainfo/com.mitchellh.ghostty.appdata.xml
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <content_rating type="oars-1.0" />
  <description>
    <p>
      👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
    </p>
  </description>
  <developer id="com.mitchellh">
    <name>Mitchell Hashimoto</name>
  </developer>
  <icon type="remote">https://raw.githubusercontent.com/ghostty-org/ghostty/refs/heads/main/images/icons/icon_256.png</icon>
  <id>com.mitchellh.ghostty</id>
  <launchable type="desktop-id">com.mitchellh.ghostty.desktop</launchable>
  <metadata_license>MIT</metadata_license>
  <name>Ghostty</name>
  <project_license>MIT</project_license>
  <summary>A terminal emulator</summary>
  <url type="homepage">https://ghostty.org</url>
</component>
EOF

cd "${TMP_DIR}"

# create app image
ARCH="$(uname -m)" appimagetool -u "${UPINFO}" "${APP_DIR}"
