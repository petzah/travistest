#!/bin/sh
set -eu

TRAVIS_DEBIAN_TARGET_ARCH="i386"
TRAVIS_DEBIAN_SUITE="sid"
TRAVIS_DEBIAN_MIRROR="${TRAVIS_DEBIAN_MIRROR:-http://ftp.de.debian.org/debian/}"


HOST_PACKAGES="debootstrap qemu-user-static binfmt-support sbuild"
CHROOT_DIR="$(pwd)/chroot"
CHROOT_PACKAGES="fakeroot,build-essential,locales"

if [ "${TRAVIS_DEBIAN_TARGET_ARCH}" != "$(dpkg --print-architecture)" ]
then
    FOREIGN="--foreign"
fi

sudo apt-get install --yes --no-install-recommends ${HOST_PACKAGES}
mkdir ${CHROOT_DIR}
sudo debootstrap ${FOREIGN} --no-check-gpg --include=${CHROOT_PACKAGES} --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
