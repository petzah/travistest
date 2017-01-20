#!/bin/sh
set -xeu

TRAVIS_DEBIAN_TARGET_ARCH="armhf"
TRAVIS_DEBIAN_SUITE="sid"
TRAVIS_DEBIAN_MIRROR="${TRAVIS_DEBIAN_MIRROR:-http://httpredir.debian.org/debian/}"
TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS="${TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS:-}"


HOST_PACKAGES="debootstrap qemu-user-static binfmt-support sbuild"
CHROOT_DIR="$(pwd)/chroot"
SRC_DIR="/src"
BUILD_DIR="/build"
CHROOT_PACKAGES="fakeroot,build-essential,locales"
CHROOT_PACKAGES_EXCLUDE="init,systemd-sysv"

if [ "${TRAVIS_DEBIAN_TARGET_ARCH}" != "$(dpkg --print-architecture)" ]
then
    FOREIGN="--foreign"
fi

mkdir -p ${CHROOT_DIR}/${SRC_DIR} ${CHROOT_DIR}/${BUILD_DIR}
mv * .travis.yml .git ${CHROOT_DIR}/${SRC_DIR} || true
sudo apt-get install --yes --no-install-recommends ${HOST_PACKAGES}
sudo debootstrap ${FOREIGN} --verbose --no-check-gpg --include=${CHROOT_PACKAGES} --exclude=${CHROOT_PACKAGES_EXCLUDE} --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
sudo cp /usr/bin/qemu-$(dpkg-architecture -a${TRAVIS_DEBIAN_TARGET_ARCH} -qDEB_HOST_ARCH_CPU)-static ${CHROOT_DIR}/usr/bin/
sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
#sudo echo "en_US.UTF-8 UTF-8" >> ${CHROOT_DIR}/etc/locale.gen
#sudo chroot ${CHROOT_DIR} /usr/sbin/locale-gen
sudo sbuild-createchroot --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${FOREIGN} --setup-only ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}

sudo chroot ${CHROOT_DIR} /bin/bash -x <<EOF
apt-get update 
apt-get --yes dist-upgrade
apt-get --yes install devscripts pkg-config gbp-buildpackage
mk-build-deps --host-arch ${TRAVIS_DEBIAN_TARGET_ARCH} --install --remove --tool 'apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' ${SRC_DIR}/debian/control
cd ${SRC_DIR}
gbp buildpackage ${TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS} --git-ignore-branch --git-export-dir=${BUILD_DIR} --git-builder='debuild -i -I -uc -us -sa'
ls -l ${BUILD_DIR}
EOF
