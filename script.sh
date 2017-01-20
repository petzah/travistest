#!/bin/sh
set -xeu

TRAVIS_DEBIAN_TARGET_ARCH="${TRAVIS_DEBIAN_TARGET_ARCH:-$(dpkg --print-architecture)}"
TRAVIS_DEBIAN_SUITE="${TRAVIS_DEBIAN_SUITE:-}"
TRAVIS_DEBIAN_MIRROR="${TRAVIS_DEBIAN_MIRROR:-http://httpredir.debian.org/debian/}"
TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS="${TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS:-}"

HOST_PACKAGES="debootstrap qemu-user-static binfmt-support sbuild"
CHROOT_DIR="$(pwd)/chroot"
SRC_DIR="/src"
BUILD_DIR="/build"
CHROOT_PACKAGES="fakeroot,build-essential,locales"
CHROOT_PACKAGES_EXCLUDE="init,systemd-sysv"

# borrowed from qemu-debootstrap
case "${TRAVIS_DEBIAN_TARGET_ARCH}" in
  alpha|arm|armeb|i386|m68k|mips|mipsel|mips64el|ppc64|sh4|sh4eb|sparc|sparc64|s390x)
    qemu_arch="${TRAVIS_DEBIAN_TARGET_ARCH}"
  ;;
  amd64)
    qemu_arch="x86_64"
  ;;
  armel|armhf)
    qemu_arch="arm"
  ;;
  arm64)
    qemu_arch="aarch64"
  ;;
  lpia)
    qemu_arch="i386"
  ;;
  powerpc|powerpcspe)
    qemu_arch="ppc"
  ;;
  ppc64el)
    qemu_arch="ppc64le"
  ;;
  *)
    die "Sorry, I don't know how to support arch %s" "$arch"
  ;;
esac

if [ "${TRAVIS_DEBIAN_TARGET_ARCH}" != "$(dpkg --print-architecture)" ]
then
    FOREIGN="--foreign"
fi
FOREIGN="${FOREIGN:-}"

mkdir -p ${CHROOT_DIR}/${SRC_DIR} ${CHROOT_DIR}/${BUILD_DIR}
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch
mv * .travis.yml .git .gitignore ${CHROOT_DIR}/${SRC_DIR} || true
#sudo add-apt-repository --yes 'deb http://archive.ubuntu.com/ubuntu xenial main restricted universe multiverse' # we need newer qemu-user-static
#sudo apt-get update
sudo apt-get install --yes --no-install-recommends ${HOST_PACKAGES}
sudo debootstrap ${FOREIGN} --verbose --no-check-gpg --include=${CHROOT_PACKAGES} --exclude=${CHROOT_PACKAGES_EXCLUDE} --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}
if [ ! -z "${FOREIGN}" ]
then
    sudo cp /usr/bin/qemu-${qemu_arch}-static ${CHROOT_DIR}/usr/bin/
    sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
fi
sudo sbuild-createchroot --arch=${TRAVIS_DEBIAN_TARGET_ARCH} ${FOREIGN} --setup-only ${TRAVIS_DEBIAN_SUITE} ${CHROOT_DIR} ${TRAVIS_DEBIAN_MIRROR}

sudo chroot ${CHROOT_DIR} /bin/bash -x <<EOF
apt-get install --yes --no-install-recommends devscripts pkg-config git-buildpackage equivs locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
cd ${SRC_DIR}
mk-build-deps --install --remove --tool "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes" debian/control
git checkout .travis.yml || true
for X in \$(git branch -r | grep -v HEAD); do git branch --track \$(echo "\${X}" | perl -pe 's:^.*?/::') \${X} || true; done
gbp buildpackage ${TRAVIS_DEBIAN_GIT_BUILDPACKAGE_OPTIONS} --git-ignore-branch --git-export-dir=${BUILD_DIR} --git-builder='debuild -i -I -uc -us -sa'
ls -l ${BUILD_DIR}
EOF
