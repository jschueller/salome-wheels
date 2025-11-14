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

# configuration
cd /tmp
git clone --depth 1 -b agy/43708_pip_exp https://github.com/jschueller/configuration.git

# kernel
cd /tmp
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/salome
git clone --depth 1 -b jsr/43708_pip_exp https://github.com/jschueller/kernel.git
cd kernel
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DSALOME_CMAKE_DEBUG=ON -DSALOME_USE_64BIT_IDS=ON \
  -DSALOME_USE_LIBBATCH=ON -DSALOME_BUILD_TESTS=ON -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python-static/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python-static/${PYTAG}-${ABI}/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python-static/${PYTAG}-${ABI}/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install
make install DESTDIR=$PWD/install
# we need to copy /share for xml stuff, /bin for executables, the patched kernel/__init__.py set the corresponding env variables
cp -rv $PWD/install/usr/local/{bin,share} $PWD/install/usr/local/lib/python*/site-packages/salome
cp -rv $PWD/install/usr/local/share $PWD/install/usr/local/lib/python*/site-packages/salome/kernel
cd $PWD/install/usr/local/lib/python*/site-packages
find . -name __pycache__ | xargs rm -r

mkdir salome_kernel-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.kernel.in > salome_kernel-${VERSION}.dist-info/METADATA
echo -e "[console_scripts]\nsalome=salome.kernel:main.run_salome" > salome_kernel-${VERSION}.dist-info/entry_points.txt
cp -v ${SCRIPTPATH}/main.kernel.py salome/kernel/main.py
python ${SCRIPTPATH}/write_distinfo.py salome_kernel ${VERSION} ${TAG}
zip -r salome_kernel-${VERSION}-${TAG}.whl *
# auditwheel show salome_kernel-${VERSION}-${TAG}.whl
auditwheel repair salome_kernel-${VERSION}-${TAG}.whl -w /io/wheelhouse/

cd /tmp
rm -rf salome*
unzip /io/wheelhouse/salome_kernel-${VERSION}-${TAG}.*.whl

# check ldd doesnt crash because of auditwheel --remove-rpath
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:salome_kernel.libs/ ldd salome/bin/salome/SALOME_Container

# libwith_loggerTraceCollector.so is dynamically loaded, so keep the original name
cp -v salome_kernel.libs/libwith_loggerTraceCollector-*.so salome_kernel.libs/libwith_loggerTraceCollector.so
zip /io/wheelhouse/salome_kernel-${VERSION}-${TAG}.*.whl salome_kernel.libs/libwith_loggerTraceCollector.so

# bootstrap
cd /tmp
git clone -b V9_14_0 --depth 1 https://github.com/SalomePlatform/salome_bootstrap.git
cd salome_bootstrap
sed -i "19iCMAKE_MINIMUM_REQUIRED(VERSION 3.0)" CMakeLists.txt
cmake -DCONFIGURATION_ROOT_DIR=/tmp/configuration -DCMAKE_POLICY_VERSION_MINIMUM=3.5 .
make install
# no wheel, this module is just needed at configuration time
PYVERD2=`echo ${PYVERD}| sed "s|m||g"`
cp -rv /usr/local/__SALOME_BOOTSTRAP__/SalomeOnDemandTK /opt/python-static/${PYTAG}-${ABI}/lib/python${PYVERD2}/site-packages

# yacs
cd /tmp
git clone --depth 1 -b jsr/43708_pip https://github.com/jschueller/yacs.git
cd yacs
sed -i "/err_py2yacs_invalid/d" ./src/py2yacs/Test/{CMakeLists.txt,Py2yacsTest.cxx}  # yields SyntaxWarning
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DSALOMEBOOTSTRAP_ROOT_DIR=/tmp/salome_bootstrap \
  -DKERNEL_ROOT_DIR=/usr/local \
  -DSALOME_BUILD_GUI=OFF \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=ON -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python-static/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python-static/${PYTAG}-${ABI}/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python-static/${PYTAG}-${ABI}/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install

make install DESTDIR=$PWD/install -j1
cp -rv $PWD/install/usr/local/{bin,share} $PWD/install/usr/local/lib/python*/site-packages/salome
cd $PWD/install/usr/local/lib/python*/site-packages
find . -name __pycache__ | xargs rm -r
mkdir salome_yacs-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.yacs.in > salome_yacs-${VERSION}.dist-info/METADATA
echo -e "[console_scripts]\ndriver=salome.yacs:main.run_driver" > salome_yacs-${VERSION}.dist-info/entry_points.txt
cp -v ${SCRIPTPATH}/main.yacs.py salome/yacs/main.py
python ${SCRIPTPATH}/write_distinfo.py salome_yacs ${VERSION} ${TAG}
zip -r salome_yacs-${VERSION}-${TAG}.whl *
# auditwheel show salome_yacs-${VERSION}-${TAG}.whl
auditwheel repair salome_yacs-${VERSION}-${TAG}.whl -w /io/wheelhouse/

cd /tmp
git clone --depth 1 -b V`echo ${VERSION}|sed "s|\.|_|g"|sed "s|_post[0-9]||g"` https://github.com/SalomePlatform/py2cpp.git
cd py2cpp
# dont explicitely link Python libs for Unix wheels
sed -i "s|\${PYTHON_LIBRARIES}|dl pthread util z|g" src/CMakeLists.txt
# add link to libpython deps since we still have to link the test executables
# sed -i "s|\${PYTHON_LIBRARIES}|\${PYTHON_LIBRARIES} dl pthread util|g" src/Test/CMakeLists.txt
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=ON -DSALOME_BUILD_DOC=OFF \
  -DPYTHON_EXECUTABLE=/opt/python-static/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python-static/${PYTAG}-${ABI}/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python-static/${PYTAG}-${ABI}/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install

cd /tmp
git clone --depth 1 -b jsr/43708_pip https://github.com/jschueller/ydefx.git
cd ydefx
# add link to libpython deps since we still have to link the test executables
# sed -i "s|${py2cpp_lib}|${py2cpp_lib} dl pthread util|g" src/cpp/Test/CMakeLists.txt
cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCONFIGURATION_ROOT_DIR=/tmp/configuration \
  -DKERNEL_ROOT_DIR=/usr/local \
  -DSALOME_CMAKE_DEBUG=ON \
  -DSALOME_BUILD_TESTS=ON -DSALOME_BUILD_DOC=OFF \
  -DYDEFX_BUILD_GUI=OFF \
  -DPYTHON_EXECUTABLE=/opt/python-static/${PYTAG}-${ABI}/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python-static/${PYTAG}-${ABI}/include/python${PYVERD} \
  -DPYTHON_LIBRARY=/opt/python-static/${PYTAG}-${ABI}/lib/libpython${PYVERD}.a \
  -B build .
cd build
make install

make install DESTDIR=$PWD/install
cp -rv $PWD/install/usr/local/bin $PWD/install/usr/local/lib/python*/site-packages/salome
# different layout than kernel/yacs
cd $PWD/install/usr/local/lib/python*/site-packages/salome
mkdir salome
mv bin salome
mkdir pydefx-${VERSION}.dist-info
sed "s|@PACKAGE_VERSION@|${VERSION}|g" ${SCRIPTPATH}/METADATA.pydefx.in > pydefx-${VERSION}.dist-info/METADATA
NOARCH=py3-none-any
python ${SCRIPTPATH}/write_distinfo.py pydefx ${VERSION} ${NOARCH}
sed -i "s|Root-Is-Purelib: false|Root-Is-Purelib: true|g" pydefx-${VERSION}.dist-info/WHEEL
zip -r pydefx-${VERSION}-${NOARCH}.whl *
cp -v pydefx-${VERSION}-${NOARCH}.whl /io/wheelhouse/
