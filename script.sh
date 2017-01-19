#!/bin/sh
set -xeu

TRAVIS_DEBIAN_TARGET_ARCH="i386"
TRAVIS_DEBIAN_SUITE="sid"
TRAVIS_DEBIAN_MIRROR="${TRAVIS_DEBIAN_MIRROR:-http://httpredir.debian.org/debian/}"


HOST_PACKAGES="debootstrap qemu-user-static binfmt-support sbuild"
CHROOT_DIR="$(pwd)/chroot"
SRC_DIR="${CHROOT_DIR}/src"
CHROOT_PACKAGES="fakeroot,build-essential,locales"
CHROOT_PACKAGES_EXCLUDE="init,systemd-sysv"

if [ "${TRAVIS_DEBIAN_TARGET_ARCH}" != "$(dpkg --print-architecture)" ]
then
    FOREIGN="--foreign"
fi

mkdir ${SRC_DIR}
find -exec mv {} ${SRC_DIR} \;
ls -lAR
mkdir ${CHROOT_DIR}
exit 0
sudo apt-get install --yes --no-install-recommends ${HOST_PACKAGES}
sudo debootstrap ${FOREIGN} --verbose --no-check-gpg --include=${CHROOT_PACKAGES} --exclude=${CHROOT_PACKAGES_EXCLUDE} --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
sudo cp /usr/bin/qemu-${TRAVIS_DEBIAN_TARGET_ARCH}-static ${CHROOT_DIR}/usr/bin/
sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
#sudo echo "en_US.UTF-8 UTF-8" >> ${CHROOT_DIR}/etc/locale.gen
#sudo chroot ${CHROOT_DIR} /usr/sbin/locale-gen
sudo sbuild-createchroot --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${FOREIGN} --setup-only ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
sudo chroot ${CHROOT_DIR} apt-get update && apt-get dist-upgrade --yes
