#!/bin/sh
set -x -e
# cp37m cp38 cp39 cp310 cp311
docker run --rm -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /io/test-wheels-linux.sh 9.14.0 cp311

