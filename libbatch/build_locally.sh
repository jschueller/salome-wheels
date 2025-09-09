#!/bin/sh
set -e
docker build docker/manylinux -t libbatch/manylinux

for pyver in cp38 cp39 cp310 cp311; do
  docker run --rm -v `pwd`:/io libbatch/manylinux /io/build-wheels-linux.sh 2.5.0.post1 ${pyver}
done
