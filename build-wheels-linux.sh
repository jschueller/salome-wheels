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
# export OMNIORB_VERSION=4.2.5
# curl -L https://downloads.sourceforge.net/omniorb/omniORB-${OMNIORB_VERSION}.tar.bz2|tar xj
# cd omniORB*
# ./configure --with-openssl=/usr
# make
# make install
# make install DESTDIR=/tmp/install_omniorb
# cd /tmp
# curl -L https://downloads.sourceforge.net/omniorb/omniORBpy/omniORBpy-${OMNIORB_VERSION}/omniORBpy-${OMNIORB_VERSION}.tar.bz2|tar xj
# cd omniORBpy*
# ./configure --with-omniorb=/usr/local
# make
# make install
# make install DESTDIR=/tmp/install_omniorb
# cd /tmp/install_omniorb/usr/local/lib/python*/site-packages
# find . -name __pycache__ | xargs rm -r
# mkdir salome_omniorb-${OMNIORB_VERSION}.dist-info
# sed "s|@PACKAGE_VERSION@|${OMNIORB_VERSION}|g" ${SCRIPTPATH}/METADATA.omniorb.in > salome_omniorb-${OMNIORB_VERSION}.dist-info/METADATA
# cat salome_omniorb-${OMNIORB_VERSION}.dist-info/METADATA
# python ${SCRIPTPATH}/write_distinfo.py salome_omniorb ${OMNIORB_VERSION} ${TAG}
# zip -r salome_omniorb-${OMNIORB_VERSION}-${TAG}.whl *
# auditwheel show salome_omniorb-${OMNIORB_VERSION}-${TAG}.whl
# auditwheel repair salome_omniorb-${OMNIORB_VERSION}-${TAG}.whl -w /io/wheelhouse/

# libbatch
# export LIBBATCH_VERSION=2.5.0
# git clone --depth 1 -b V`echo ${LIBBATCH_VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/libbatch.git
# cd libbatch
# sed -i "s|PYTHON_LIBRARIES|ZZZ|g" src/Python/CMakeLists.txt
# cmake -LAH -DCMAKE_BUILD_TYPE=Release \
#   -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}/bin/python \
#   -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}/include/python${PYVERD} -DPYTHON_LIBRARY=dummy \
#   -DLIBBATCH_CXX_STANDARD=17 \
#   -B build .
# cd build
# make install
# make install DESTDIR=$PWD/install
# cd $PWD/install/usr/local/lib/python*/site-packages
# rm -rf __pycache__
# mkdir libbatch-${LIBBATCH_VERSION}.dist-info
# sed "s|@PACKAGE_VERSION@|${LIBBATCH_VERSION}|g" ${SCRIPTPATH}/METADATA.libbatch.in > libbatch-${LIBBATCH_VERSION}.dist-info/METADATA
# python ${SCRIPTPATH}/write_distinfo.py libbatch ${LIBBATCH_VERSION} ${TAG}
# zip -r libbatch-${LIBBATCH_VERSION}-${TAG}.whl *.py *.so libbatch-${LIBBATCH_VERSION}.dist-info
# auditwheel show libbatch-${LIBBATCH_VERSION}-${TAG}.whl
# auditwheel repair libbatch-${LIBBATCH_VERSION}-${TAG}.whl -w /io/wheelhouse/

# configuration
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/configuration.git
# sed -i "s|NO_SYSTEM_ENVIRONMENT_PATH||g" configuration/cmake/SalomeMacros.cmake

# install Engines.py into spdir instead spdir/salome (INSTALL_PYIDL_DIR)
# sed -i "s|site-packages/salome|site-packages|g" configuration/cmake/UseOmniORB.cmake

# kernel
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/salome
pip install "numpy<2" "psutil<6"
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/kernel.git
cd kernel
# patch -p1 -i ${SCRIPTPATH}/kernel_debug.patch
patch -p1 -i ${SCRIPTPATH}/kernel_root_dir.patch
git diff
# exit 1

# transitive link to libutil.so.1 for forkpty/openpty symbols as we link to static python
grep -lr "PYTHON_LIBRARIES" . | xargs sed -i "s|\${PYTHON_LIBRARIES}|\${PYTHON_LIBRARIES} util|g"
# sed -i 's|CACHE PATH "Install path: SALOME Python stuff"|CACHE STRING "Install path: SALOME Python stuff"|g' CMakeLists.txt 
git diff
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DSALOME_CMAKE_DEBUG=ON -DSALOME_USE_64BIT_IDS=ON \
  -DSALOME_USE_LIBBATCH=ON -DSALOME_BUILD_TESTS=OFF -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}-static/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}-static/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python/${PYTAG}-${ABI}-static/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install
# 
# export SALOME_VERBOSE=1
# export SALOME_VERBOSE_LEVEL=2
# export LD_LIBRARY_PATH=/usr/local/lib/:/usr/local/lib/salome
# export PYTHONPATH=/usr/local/bin/salome/:/usr/local/lib/salome/:/usr/local/lib/python3.10/site-packages:/usr/local/lib/python3.10/site-packages/salome
# export KERNEL_ROOT_DIR=/usr/local
# python -c "import salome.kernel"
# python -c "import salome"
# python -c "import salome; salome.salome_init()"

# exit 1
make install DESTDIR=$PWD/install -j20

cp -v $PWD/install/usr/local/lib/salome/_*.so $PWD/install/usr/local/lib/python*/site-packages
cp -v $PWD/install/usr/local/bin/salome/*.py $PWD/install/usr/local/lib/python*/site-packages
cp -rv $PWD/install/usr/local/share $PWD/install/usr/local/lib/python*/site-packages
cd $PWD/install/usr/local/lib/python*/site-packages
find . -name __pycache__ | xargs rm -r

# drop the /salome top-level directory
mv salome/salome _tmp
mv salome/* .
rmdir salome
mv _tmp salome

# mkdir salome_kernel-${VERSION}.dist-info
# sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.kernel.in > salome_kernel-${VERSION}.dist-info/METADATA
# python ${SCRIPTPATH}/write_distinfo.py salome_kernel ${VERSION} ${TAG}
# zip -r salome_kernel-${VERSION}-${TAG}.whl *
# auditwheel show salome_kernel-${VERSION}-${TAG}.whl
# auditwheel repair salome_kernel-${VERSION}-${TAG}.whl -w /io/wheelhouse/

cd /tmp
# pip install salome_omniorb --pre --no-index -f /io/wheelhouse
# python -c "from omniORB import CORBA, PortableServer"

# pip install libbatch --pre --no-index -f /io/wheelhouse
# python -c "import libbatch"


# export LD_LIBRARY_PATH=/usr/local/lib/
# export PYTHONPATH=/usr/local/lib/python3.10/site-packages
# export KERNEL_ROOT_DIR=/tmp/kernel/build/install/usr/local

# export LD_LIBRARY_PATH=/usr/local/lib/:/usr/local/lib/salome
# export PYTHONPATH=/usr/local/bin/salome/:/usr/local/lib/salome/:/usr/local/lib/python3.10/site-packages
# rm -r /usr/local/lib/python3.10/site-packages/salome
# rm -r /usr/local/lib/salome
# rm -r /usr/local/bin/salome

# export SALOME_VERBOSE=1
# export SALOME_VERBOSE_LEVEL=2
# 
# # ls -l /usr/local/lib/python3.10/site-packages
# export LD_LIBRARY_PATH=/tmp/kernel/build/install/usr/local/lib/salome:/usr/local/lib
# export PYTHONPATH=/usr/local/lib/python3.10/site-packages:/tmp/kernel/build/install/usr/local/lib/python3.10/site-packages
# # export PATH=/tmp/kernel/build/install/usr/local/bin:/tmp/kernel/build/install/usr/local/bin/salome:$PATH
# #/usr/local/lib/python3.10/site-packages:/usr/local/lib/python3.10/site-packages/salome
# # ls -l /usr/local/bin
# # ls -l /usr/local/bin/salome
# 
# # pip install salome_kernel --pre --no-index -f /io/wheelhouse
# python -c "import salome"
# python -c "import salome.kernel"
# python -c "import salome; salome.salome_init()"

cd /tmp
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/yacs.git
cd yacs
# dont explicitely link Python libs to swig modules
sed -i "s|PYTHON_LIBRARIES|ZZZ|g" src/*_swig/CMakeLists.txt 
git diff
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DKERNEL_ROOT_DIR=/usr/local \
  -DSALOME_BUILD_GUI=OFF \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=OFF -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}-static/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}-static/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python/${PYTAG}-${ABI}-static/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install

make install DESTDIR=$PWD/install -j20
cd $PWD/install/usr/local/lib/python*/site-packages/salome
find . -name __pycache__ | xargs rm -r
mkdir salome_yacs-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.yacs.in > salome_yacs-${VERSION}.dist-info/METADATA
python ${SCRIPTPATH}/write_distinfo.py salome_yacs ${VERSION} ${TAG}
zip -r salome_yacs-${VERSION}-${TAG}.whl *
auditwheel show salome_yacs-${VERSION}-${TAG}.whl
auditwheel repair salome_yacs-${VERSION}-${TAG}.whl -w /io/wheelhouse/

# pip install salome_yacs --pre --no-index -f /io/wheelhouse
# python -c "import evalyfx"
# python -c "import evalyfx; session=evalyfx.YACSEvalSession()"

cd /tmp
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/py2cpp.git
cd py2cpp
# dont explicitely link Python libs for Unix wheels
sed -i "s|PYTHON_LIBRARIES|ZZZ|g" src/CMakeLists.txt

# drop cppunit
sed -i "/SalomeCppUnit/d" CMakeLists.txt
sed -i "/Test/d" src/CMakeLists.txt

cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=OFF -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}/include/python${PYVERD} \
  -DPYTHON_LIBRARY=dummy \
  -B build .
cd build
make install

cd /tmp
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/ydefx.git
cd ydefx
# disable tests
sed -i "/ADD_SUBDIRECTORY(Test)/d" src/cpp/CMakeLists.txt
git diff
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DKERNEL_ROOT_DIR=/usr/local \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=OFF -DSALOME_BUILD_DOC=OFF \
  -DYDEFX_BUILD_GUI=OFF \
  -DPYTHON_EXECUTABLE=/opt/python/${PYTAG}-${ABI}-static/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/${PYTAG}-${ABI}-static/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python/${PYTAG}-${ABI}-static/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install

make install DESTDIR=$PWD/install -j20
cd $PWD/install/usr/local/lib/python*/site-packages/salome
mkdir salome_ydefx-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.ydefx.in > salome_ydefx-${VERSION}.dist-info/METADATA
python ${SCRIPTPATH}/write_distinfo.py salome_ydefx ${VERSION} py3
zip -r salome_ydefx-${VERSION}-py3.whl *
# auditwheel show salome_ydefx-${VERSION}-py3.whl
# auditwheel repair salome_ydefx-${VERSION}-py3.whl -w /io/wheelhouse/
cp -v salome_ydefx-${VERSION}-py3.whl /io/wheelhouse/
