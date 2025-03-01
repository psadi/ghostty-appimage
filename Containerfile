FROM ghcr.io/pkgforge-dev/archlinux:latest

LABEL org.opencontainers.image.source="https://github.com/psadi/ghostty-appimage"
LABEL org.opencontainers.image.description="Container image for ghostty-appimage dependencies"
LABEL org.opencontainers.image.licenses="MIT"

COPY setup.sh setup.sh

RUN sh setup.sh
