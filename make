#!/bin/bash -e

if [ ! -z "$DEBUG" ]; then
  set -x
fi

# dependencies needed by the script or the base
# debian kernel package for the build step
apt install -y curl make rsync kmod cpio libncurses-dev \
  libssl-dev bc flex bison make gcc 

base=$PWD
for device in $(cat kernels); do
  echo "Building kernel for $device"
  source $base/$device/env

  echo "Installing packges $device"
  if [ -z "$PKDEP" ]; then
    apt install -y $PKGDEP
  fi

  dir=$(mktemp -d)
  echo "Building in $dir"
  cd $dir

  url=$(head -n1 $base/$device/source)
  src=$(tail -n1 $base/$device/source)
  echo "Downloading source from $url"
  curl -L $url -o source.tar.gz
  tar xf source.tar.gz
  cd $src

  echo "Make defconfig"
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig

  echo "Compile the kernel"
  nice make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) bindeb-pkg LOCALVERSION=$LOCALVERSION

  echo "Move kernel packages"
  mkdir -p $base/build/$device
  mv $dir/*.deb $dir/*.buildinfo $dir/*.changes $base/build/$device

  cd $base
  unset PKGDEP ARCH CROSS_COMPILE LOCALVERSION 
done
