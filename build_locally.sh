#!/bin/sh
set -x -e
docker build docker/manylinux -t salome/manylinux
mkdir -p wheelhouse
cp -v libbatch/wheelhouse/*.whl wheelhouse
cp -v omniorb/wheelhouse/*.whl wheelhouse
# cp38 cp39 cp310 cp311
abi=cp39
VERSION=9.14.0.post1
docker run --rm -e MAKEFLAGS='-j8' -v `pwd`:/io salome/manylinux /io/build-wheels-linux.sh ${VERSION} ${abi}
docker run --rm -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /io/test-wheels-linux.sh ${VERSION} ${abi}

if test "${abi}" = "cp38"
then
  docker build docker/ubuntu20 -t salome/ubuntu20
  docker run --rm -v `pwd`:/io salome/ubuntu20 /io/test-wheels-debian.sh ${VERSION} cp38
fi

if test "${abi}" = "cp39"
then
  docker build docker/debian11 -t salome/debian11
  docker run --rm -v `pwd`:/io salome/debian11 /io/test-wheels-debian.sh ${VERSION} cp39
fi

if test "${abi}" = "cp310"
then
  docker build docker/ubuntu22 -t salome/ubuntu22
  docker run --rm -v `pwd`:/io salome/ubuntu22 /io/test-wheels-debian.sh ${VERSION} cp310
fi

if test "${abi}" = "cp311"
then
  docker build docker/debian12 -t salome/debian12
  docker run --rm -v `pwd`:/io salome/debian12 /io/test-wheels-debian.sh ${VERSION} cp311
fi
