#!/bin/sh

set -xe

ABI=$1

PYTAG=${ABI/m/}
PYVERD=${ABI:2:1}.${ABI:3}

LIBBATCH_VERSION=2.5.0
cd /tmp
git clone --depth 1 -b V`echo ${LIBBATCH_VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/libbatch.git
cd libbatch
sed -i "s|\${PYTHON_LIBRARIES}||g" src/Python/CMakeLists.txt
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}/include/python${PYVERD} -DPYTHON_LIBRARY=dummy \
  -DLIBBATCH_CXX_STANDARD=17 \
  -B build .
cd build
make install
rm -r /tmp/libbatch*
