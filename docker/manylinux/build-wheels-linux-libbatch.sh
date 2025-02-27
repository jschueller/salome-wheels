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

export LIBBATCH_VERSION=2.5.0
git clone --depth 1 -b V`echo ${LIBBATCH_VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/libbatch.git
cd libbatch
sed -i "s|PYTHON_LIBRARIES|ZZZ|g" src/Python/CMakeLists.txt
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}/include/python${PYVERD} -DPYTHON_LIBRARY=dummy \
  -DLIBBATCH_CXX_STANDARD=17 \
  -B build .
cd build
make install
make install DESTDIR=$PWD/install
cd $PWD/install/usr/local/lib/python*/site-packages
rm -rf __pycache__
mkdir libbatch-${LIBBATCH_VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${LIBBATCH_VERSION}|g" ${SCRIPTPATH}/METADATA.libbatch.in > libbatch-${LIBBATCH_VERSION}.dist-info/METADATA
python ${SCRIPTPATH}/write_distinfo.py libbatch ${LIBBATCH_VERSION} ${TAG}
zip -r libbatch-${LIBBATCH_VERSION}-${TAG}.whl *.py *.so libbatch-${LIBBATCH_VERSION}.dist-info
auditwheel show libbatch-${LIBBATCH_VERSION}-${TAG}.whl
auditwheel repair libbatch-${LIBBATCH_VERSION}-${TAG}.whl -w /io/wheelhouse/
