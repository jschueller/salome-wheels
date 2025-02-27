#!/bin/sh

set -e
test $# = 1 || exit 1
python_version=$1

PYTAG=`echo cp${python_version}| cut -d "." -f-2 | sed "s|\.||g"`
ABI=${PYTAG}

curl -fSsL https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz | tar xz
cd Python*
CFLAGS="-fPIC" ./configure --with-static-libpython --enable-optimizations PKG_CONFIG_PATH=/opt/ffi/lib/pkgconfig/:/opt/ssl/lib64/pkgconfig/ LDFLAGS="-Wl,-rpath /usr/local/lib -L/opt/ssl/lib64 -L/opt/ffi/lib" --prefix=/opt/_internal/cpython-${python_version}-static
make > /dev/null 2>&1
make install > /dev/null 2>&1
cd -
rm -r Python*
cd /opt/_internal/cpython-${python_version}-static/bin
ln -s python3 python
ln -s pip3 pip
./python -c "import ssl; import ctypes"

ln -sv /opt/_internal/cpython-${python_version}-static /opt/python/${PYTAG}-${ABI}-static
