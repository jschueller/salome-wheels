#!/bin/sh
set -x -e
docker build docker/manylinux -t salome/manylinux
docker run --rm -e MAKEFLAGS='-j8' -v `pwd`:/io salome/manylinux /io/build-wheels-linux.sh 9.14.0 cp310
