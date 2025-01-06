setup_fp := "/tmp/ghostty-build"
dest_fp := "/tmp/ghostty-build/ghostty.AppDir"
cache_fp := "/tmp/offline-cache"
source_fp := "/tmp/ghostty-build/ghostty-source.tar.gz"
minisig_fp := "/tmp/ghostty-build/ghostty-source.tar.gz.minisig"

setup:
    rm -rf "{{ setup_fp }}"
    mkdir -p -- "{{ setup_fp }}" "{{ dest_fp }}/usr" "{{ cache_fp }}"
    wget https://release.files.ghostty.org/1.0.0/ghostty-source.tar.gz -O "{{ source_fp }}"
    wget https://release.files.ghostty.org/1.0.0/ghostty-source.tar.gz.minisig -O "{{ minisig_fp }}"
    minisign -V -P "${pubkey}" -m "{{ source_fp }}" -s "{{ minisig_fp }}"
    tar -zxf "{{ source_fp }}" -C "{{ setup_fp }}"
    rm -rf "{{ source_fp }}" "{{ minisig_fp }}"

[working-directory('/tmp/ghostty-build/ghostty-source')]
compile:
    zig build \
      --prefix "{{ dest_fp }}/usr" \
      -Doptimize=ReleaseFast \
      -Dcpu=baseline

[working-directory('/tmp/ghostty-build/ghostty.AppDir')]
build:
    printf '#!/bin/sh\n\nexec "$(dirname "$(readlink -f "$0")")/usr/bin/ghostty"\n' | tee AppRun > /dev/null
    chmod +x AppRun
    ln -s usr/share/applications/com.mitchellh.ghostty.desktop
    ln -s usr/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png
    ARCH=x8_64 appimagetool "{{ dest_fp }}"
