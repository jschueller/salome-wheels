#!/bin/bash

set -e -x

test $# -ge 2 || exit 1

VERSION="$1"
ABI="$2"
TEST_LIGHT="$3"

#PLATFORM=manylinux2014_x86_64
#PYTAG=${ABI/m/}
#TAG=${PYTAG}-${ABI}-${PLATFORM}
echo ""

PYVERD=${ABI:2:1}.${ABI:3}
#PYVERD=`echo ${PYVERD}| sed "s|m||g"`
# PYVERD=3.11

#SCRIPT=`readlink -f "$0"`
#SCRIPTPATH=`dirname "$SCRIPT"`
#export PATH=/opt/python/${PYTAG}-${ABI}/bin/:$PATH
SP_DIR=/usr/local/lib/python${PYVERD}/dist-packages

pip install salome.kernel --pre --no-index -f /io/wheelhouse

python -c "import salome.kernel"
python -c "from salome.kernel import salome; salome.salome_init()"

which salome
salome shell -- env
salome shell -- which SALOME_Container
salome shell -- ldd ${SP_DIR}/salome/bin/salome/SALOME_Container

export SALOME_VERBOSE=1

echo 'import salome.kernel.KernelContainer; import os.path; assert os.path.exists(salome.kernel.KernelContainer.getDftLocOfScripts())' > ensure_scripts_templ.py
salome shell -- python ensure_scripts_templ.py

if test -n "${TEST_LIGHT}"
then
  salome test -L KERNEL -VV -R KERNEL_testCrashProofContainer
else
  salome test -L KERNEL -VV -E "KERNEL_LC_LifeCycleCORBA_SWIGTest|KERNEL_LifeCycleCORBA|KERNEL_KernelHelpers|KERNEL_UnitTests"
fi

pip install salome.yacs --pre --no-index -f /io/wheelhouse

sed -i 's|__testSubDir = "bin/salome/test/kernel"|__testSubDir = "bin/salome/test/yacs"|g' ${SP_DIR}/salome/kernel/runTests.py

python -c "import salome.yacs"

for subdir in yacsloader yacsloader_swig
do
  cp -rv ${SP_DIR}/salome/share/salome/yacssamples ${SP_DIR}/salome/bin/salome/test/yacs/${subdir}/samples
done

if test -n "${TEST_LIGHT}"
then
  salome test -L YACS -VV -R YACS_PyDecorator
else
  # c++ test YACS_YacsPMMLExeTest needs YACS_ROOT_DIR
  salome test -L YACS -VV -E "YACS_YacsRuntimeTest|YACS_YacsLoaderTest|YACS_YacsPMMLExeTest"
fi

pip install pydefx --pre --no-index -f /io/wheelhouse

python -c "import pydefx"

sed -i 's|__testSubDir = "bin/salome/test/yacs"|__testSubDir = "bin/salome/test"|g' ${SP_DIR}/salome/kernel/runTests.py

if test -n "${TEST_LIGHT}"
then
  salome test -L YDEFX -VV -R YDEFX_PyExampleTest
else
  # cannot run c++ tests since libydefx.so is not mangled
  salome test -L YDEFX -VV -E "YDEFX_StudyGeneralTest|YDEFX_StudyRestartTest|YDEFX_SampleTest"
fi

# test outside salome shell
cd ${SP_DIR}/salome/bin/salome/test/pyexample
${SP_DIR}/salome/bin/salome/test/pyexample/runUnitTest.sh
