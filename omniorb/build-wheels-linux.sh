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
curl -L https://downloads.sourceforge.net/omniorb/omniORB-${VERSION}.tar.bz2|tar xj
cd omniORB*
./configure --with-openssl=/usr
make
make install
make install DESTDIR=/tmp/omniorb_install
cd -

# omniorbpy
curl -L https://downloads.sourceforge.net/omniorb/omniORBpy/omniORBpy-${VERSION}/omniORBpy-${VERSION}.tar.bz2|tar xj
cd omniORBpy*
patch -p1 -i ${SCRIPTPATH}/omniorb-noinitfile.patch
./configure --with-omniorb=/usr/local
make
make install DESTDIR=/tmp/omniorb_install

cd /tmp/omniorb_install/usr/local/lib/python*/site-packages
find . -name __pycache__ | xargs rm -r
mkdir omniORB/bin
cp /tmp/omniorb_install/usr/local/bin/omniNames omniORB/bin
cp -v ${SCRIPTPATH}/main.py omniORB/main.py

# write metadata
mkdir salome_omniorb-${VERSION}.dist-info
echo -e "[console_scripts]\nomniNames=omniORB:main.run_omniNames" > salome_omniorb-${VERSION}.dist-info/entry_points.txt
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.in > salome_omniorb-${VERSION}.dist-info/METADATA
python ${SCRIPTPATH}/write_distinfo.py salome_omniorb ${VERSION} ${TAG}

# create archive
zip -r salome_omniorb-${VERSION}-${TAG}.whl *.py *omni* CosNaming* salome_omniorb-${VERSION}.dist-info

auditwheel show salome_omniorb-${VERSION}-${TAG}.whl
auditwheel repair salome_omniorb-${VERSION}-${TAG}.whl -w /io/wheelhouse/

# test
cd /tmp
pip install salome-omniorb --pre --no-index -f /io/wheelhouse
python -c "from omniORB import CORBA, PortableServer"
