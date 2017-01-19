#!/bin/sh
set -xeu

TRAVIS_DEBIAN_TARGET_ARCH="i386"
TRAVIS_DEBIAN_SUITE="sid"
TRAVIS_DEBIAN_MIRROR="${TRAVIS_DEBIAN_MIRROR:-http://httpredir.debian.org/debian/}"


HOST_PACKAGES="debootstrap qemu-user-static binfmt-support sbuild"
CHROOT_DIR="$(pwd)/chroot"
CHROOT_PACKAGES="fakeroot,build-essential,locales"

if [ "${TRAVIS_DEBIAN_TARGET_ARCH}" != "$(dpkg --print-architecture)" ]
then
    FOREIGN="--foreign"
fi

sudo apt-get install --yes --no-install-recommends ${HOST_PACKAGES}
mkdir ${CHROOT_DIR}
sudo debootstrap ${FOREIGN} --verbose --no-check-gpg --include=${CHROOT_PACKAGES} --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
sudo cp /usr/bin/qemu-${TRAVIS_DEBIAN_TARGET_ARCH}-static ${CHROOT_DIR}/usr/bin/
sudo tail -f ${CHROOT_DIR}/debootstrap/debootstrap.log &
sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
sudo echo "en_US.UTF-8 UTF-8" >> ${CHROOT_DIR}/etc/locale.gen
sudo chroot ${CHROOT_DIR} /usr/sbin/locale-gen
sudo sbuild-createchroot --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${FOREIGN} --setup-only ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
