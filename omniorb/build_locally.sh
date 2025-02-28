#!/bin/sh
docker build docker/manylinux -t omniorb/manylinux
for pyver in cp37m cp38 cp39 cp310 cp311; do docker run --rm -e MAKEFLAGS='-j8' -v `pwd`:/io omniorb/manylinux /io/build-wheels-linux.sh 4.2.5 ${pyver}; done
