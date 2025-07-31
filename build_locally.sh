#!/bin/sh
set -x -e
docker build docker/manylinux -t salome/manylinux
mkdir -p wheelhouse
cp -v libbatch/wheelhouse/*.whl wheelhouse
cp -v omniorb/wheelhouse/*.whl wheelhouse
# cp38 cp39 cp310 cp311
abi=cp39
docker run --rm -e MAKEFLAGS='-j8' -v `pwd`:/io salome/manylinux /io/build-wheels-linux.sh 9.14.0 ${abi}
docker run --rm -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /io/test-wheels-linux.sh 9.14.0 ${abi}
docker run --rm -v `pwd`:/io debian:11 /io/test-wheels-debian.sh 9.14.0 ${abi}
