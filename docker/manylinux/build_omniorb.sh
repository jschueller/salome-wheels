#!/bin/sh

set -xe

ABI=$1

PYTAG=${ABI/m/}
PYVERD=${ABI:2:1}.${ABI:3}

OMNIORB_VERSION=4.2.5
PATH=/opt/python/${PYTAG}-${ABI}/bin/:$PATH

cd /tmp
# curl --retry 10 -LO https://downloads.sourceforge.net/omniorb/omniORB-${OMNIORB_VERSION}.tar.bz2
tar xfj omniORB-${OMNIORB_VERSION}.tar.bz2
cd omniORB*
./configure --with-openssl=/usr
make > /dev/null 2>&1
make install > /dev/null 2>&1

cd /tmp
# curl --retry 10 -LO https://downloads.sourceforge.net/omniorb/omniORBpy/omniORBpy-${OMNIORB_VERSION}/omniORBpy-${OMNIORB_VERSION}.tar.bz2
tar xfj omniORBpy-${OMNIORB_VERSION}.tar.bz2
cd omniORBpy*
patch -p1 -i /tmp/omniorb-noinitfile.patch
./configure --with-omniorb=/usr/local
make > /dev/null 2>&1
make install > /dev/null 2>&1

PYTHONPATH=/usr/local/lib/python${PYVERD}/site-packages python -c "from omniORB import CORBA, PortableServer"

rm -r /tmp/omniORB-${OMNIORB_VERSION} /tmp/omniORBpy-${OMNIORB_VERSION}
