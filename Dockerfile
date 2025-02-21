FROM ghcr.io/pkgforge-dev/archlinux:latest

COPY setup.sh setup.sh

RUN sh setup.sh
