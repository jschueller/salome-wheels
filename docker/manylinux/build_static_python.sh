#!/bin/sh

set -xe
test $# = 1 || exit 1
python_version=$1

PYTAG=`echo cp${python_version}| cut -d "." -f-2 | sed "s|\.||g"`
ABI=${PYTAG}

curl -fSsL https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz | tar xz
cd Python-${python_version}

# build static modules
for mod in array math cmath _contextvars _struct _weakref _random _elementtree pyexpat _pickle _datetime _zoneinfo _bisect _heapq _asyncio _json _lsprof _multiprocessing _multibytecodec _opcode _pickle _queue _statistics unicodedata select _typing mmap _csv _socket _posixsubprocess audioop _md5 _sha1 _sha256 _sha512 _sha3 _blake2 binascii parser
do
  sed -i "s|^#${mod} |${mod} |g" Modules/Setup
done
cat Modules/Setup

CFLAGS="-fPIC" ./configure --disable-shared --with-static-libpython PKG_CONFIG_PATH=/opt/ffi/lib/pkgconfig/:/opt/ssl/lib64/pkgconfig/ LDFLAGS="-Wl,-rpath /usr/local/lib -L/opt/ssl/lib64 -L/opt/ffi/lib" --prefix=/opt/_internal/cpython-${python_version}-static
make > /dev/null 2>&1
make install > /dev/null 2>&1
# copy separate static libexpat needed to link against libpython (>=3.11), else create dummy
cp -r Modules/expat/libexpat.a /opt/_internal/cpython-${python_version}-static/lib || ar -r /opt/_internal/cpython-${python_version}-static/lib/libexpat.a
cd -
rm -r Python-${python_version}
cd /opt/_internal/cpython-${python_version}-static/bin
ln -s python3 python
ln -s pip3 pip
./python -c "import ssl; import ctypes"
./python -c "import math; import cmath"
./python -c "import _asyncio; import unicodedata; import _sha1"
./python -c "import pyexpat"

mkdir -p /opt/python-static/
ln -sv /opt/_internal/cpython-${python_version}-static /opt/python-static/${PYTAG}-${ABI}

find /opt/python-static/${PYTAG}-${ABI}/ -name "*.so"
