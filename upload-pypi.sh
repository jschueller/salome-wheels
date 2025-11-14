#!/bin/sh

# upload wheels to PyPI repository using Twine

LIBBATCH_VERSION=2.5.0
OMNIORB_VERSION=4.2.5
SALOME_VERSION=9.14.0.post5

# assumes a [testpypi] section in your .pypirc
REPO=pypi

set -e
for ABI in cp38 cp39 cp310 cp311
do
  twine upload -r ${REPO} wheelhouse/libbatch-${LIBBATCH_VERSION}-*-${ABI}-manylinux*.whl
  twine upload -r ${REPO} wheelhouse/salome_omniorb-${OMNIORB_VERSION}-*-${ABI}-manylinux*.whl
  twine upload -r ${REPO} wheelhouse/salome_kernel-${SALOME_VERSION}-*-${ABI}-manylinux*.whl
  twine upload -r ${REPO} wheelhouse/salome_yacs-${SALOME_VERSION}-*-${ABI}-manylinux*.whl
  twine upload -r ${REPO} wheelhouse/pydefx-${SALOME_VERSION}-py3-none-any.whl
done

