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

# libbatch
ls -l /opt/python/${PYTAG}-${ABI}

git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"|sed "s|_post[0-9]||g"` https://github.com/SalomePlatform/libbatch.git
cd libbatch
sed -i "s|\${PYTHON_LIBRARIES}||g" src/Python/CMakeLists.txt
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PWD/install \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}/include/python${PYVERD} -DPYTHON_LIBRARY=dummy \
  -DLIBBATCH_CXX_STANDARD=17 \
  -DCMAKE_INSTALL_RPATH="${PWD}/install/lib" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DLIBBATCH_RM_COMMAND=/bin/rm \
  -DLIBBATCH_SH_COMMAND=/bin/sh \
  -DLIBBATCH_CP_COMMAND=/bin/cp \
  -DLIBBATCH_MKDIR_COMMAND=/bin/mkdir \
  -B build .
make install -C build
cd install/lib/python*/site-packages
rm -rf __pycache__

# write metadata
mkdir libbatch-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.in > libbatch-${VERSION}.dist-info/METADATA
python ${SCRIPTPATH}/write_distinfo.py libbatch ${VERSION} ${TAG}

# create archive
zip -r libbatch-${VERSION}-${TAG}.whl *.py *.so libbatch-${VERSION}.dist-info

auditwheel show libbatch-${VERSION}-${TAG}.whl
auditwheel repair libbatch-${VERSION}-${TAG}.whl -w /io/wheelhouse/

# test
cd /tmp
pip install libbatch --pre --no-index -f /io/wheelhouse
python -c "import libbatch"
