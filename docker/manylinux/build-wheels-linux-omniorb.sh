#!/bin/sh

set -e -x

test $# = 2 || exit 1

VERSION="$1"
ABI="$2"

PLATFORM=manylinux2014_x86_64
PYTAG=${ABI/m/}
TAG=${PYTAG}-${ABI}-${PLATFORM}
PYVERD=${ABI:2:1}.${ABI:3}

SCRIPT=`readlink -f "$0"`
SCRIPTPATH=`dirname "$SCRIPT"`
export PATH=/opt/python/${PYTAG}-${ABI}/bin/:$PATH

cd /tmp

# omniorb
export OMNIORB_VERSION=4.2.5
curl -L https://downloads.sourceforge.net/omniorb/omniORB-${OMNIORB_VERSION}.tar.bz2|tar xj
cd omniORB*
./configure --with-openssl=/usr
make -j8
