#!/bin/sh

set -xe

ABI=$1

PYTAG=${ABI/m/}
PYVERD=${ABI:2:1}.${ABI:3}

OMNIORB_VERSION=4.2.5
PATH=/opt/python/${PYTAG}-${ABI}/bin/:$PATH

cd /tmp
curl -L https://downloads.sourceforge.net/omniorb/omniORB-${OMNIORB_VERSION}.tar.bz2|tar xj
cd omniORB*
./configure --with-openssl=/usr
make
make install

cd /tmp
curl -L https://downloads.sourceforge.net/omniorb/omniORBpy/omniORBpy-${OMNIORB_VERSION}/omniORBpy-${OMNIORB_VERSION}.tar.bz2|tar xj
cd omniORBpy*
patch -p1 -i /tmp/omniorb-noinitfile.patch
./configure --with-omniorb=/usr/local
make
make install

PYTHONPATH=/usr/local/lib/python${PYVERD}/site-packages python -c "from omniORB import CORBA, PortableServer"

rm -r /tmp/omniORB*
