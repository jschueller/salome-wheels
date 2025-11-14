#!/bin/sh
set -x -e

if test $# -eq 1
then
  abi=$1
else
  abi=cp39
fi

docker build docker/manylinux -t salome/manylinux
mkdir -p wheelhouse
cp -v libbatch/wheelhouse/*.whl wheelhouse
cp -v omniorb/wheelhouse/*.whl wheelhouse
VERSION=9.14.0.post5
docker run --rm -e MAKEFLAGS='-j16' -v `pwd`:/io salome/manylinux /io/build-wheels-linux.sh ${VERSION} ${abi}
docker run --rm -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /io/test-wheels-linux.sh ${VERSION} ${abi} light

if test "${abi}" = "cp38"
then
  docker build docker/ubuntu20 -t salome/ubuntu20
  docker run --rm -v `pwd`:/io salome/ubuntu20 /io/test-wheels-debian.sh ${VERSION} cp38 light
fi

if test "${abi}" = "cp39"
then
  docker build docker/debian11 -t salome/debian11
  docker run --rm -v `pwd`:/io salome/debian11 /io/test-wheels-debian.sh ${VERSION} cp39 light
fi

if test "${abi}" = "cp310"
then
  docker build docker/ubuntu22 -t salome/ubuntu22
  docker run --rm -v `pwd`:/io salome/ubuntu22 /io/test-wheels-debian.sh ${VERSION} cp310 light
fi

if test "${abi}" = "cp311"
then
  docker build docker/debian12 -t salome/debian12
  docker run --rm -v `pwd`:/io salome/debian12 /io/test-wheels-debian.sh ${VERSION} cp311 light
fi

# retry --until=success -- ./build_locally.sh cp39
