#!/bin/sh

set -e -x

test $# = 2 || exit 1

VERSION="$1"
ABI="$2"

PLATFORM=manylinux2014_x86_64
PYTAG=${ABI/m/}
TAG=${PYTAG}-${ABI}-${PLATFORM}
PYVERD=${ABI:2:1}.${ABI:3}
PYVERD=`echo ${PYVERD}| sed "s|m||g"`

SCRIPT=`readlink -f "$0"`
SCRIPTPATH=`dirname "$SCRIPT"`
export PATH=/opt/python/${PYTAG}-${ABI}/bin/:$PATH

# required by kernel
export HOME=/root
export USER=root

cd /tmp

pip install "numpy<2" "psutil<6"
pip install salome.kernel --pre --no-index -f /io/wheelhouse

python -c "import salome.kernel"
python -c "from salome.kernel import salome; salome.salome_init()"

which salome
salome shell -- env
salome shell -- which SALOME_Container
salome shell -- ldd /opt/python/${PYTAG}-${ABI}/lib/python${PYVERD}/site-packages/salome/bin/salome/SALOME_Container

export SALOME_VERBOSE=1

echo 'import salome.kernel.KernelContainer; import os.path; assert os.path.exists(salome.kernel.KernelContainer.getDftLocOfScripts())' > ensure_scripts_templ.py
salome shell -- python ensure_scripts_templ.py


salome test -L KERNEL -VV -E "KERNEL_LC_LifeCycleCORBA_SWIGTest|KERNEL_LifeCycleCORBA|KERNEL_KernelHelpers|KERNEL_UnitTests"

pip install salome.yacs --pre --no-index -f /io/wheelhouse

sed -i 's|__testSubDir = "bin/salome/test/kernel"|__testSubDir = "bin/salome/test/yacs"|g' /opt/python/${PYTAG}-${ABI}/lib/python${PYVERD}/site-packages/salome/kernel/runTests.py

python -c "import salome.yacs"

for subdir in yacsloader yacsloader_swig
do
  cp -rv /opt/python/${PYTAG}-${ABI}/lib/python${PYVERD}/site-packages/salome/share/salome/yacssamples /opt/python/${PYTAG}-${ABI}/lib/python${PYVERD}/site-packages/salome/bin/salome/test/yacs/${subdir}/samples
done

# c++ test YACS_YacsPMMLExeTest needs YACS_ROOT_DIR
salome test -L YACS -VV -E "YACS_YacsRuntimeTest|YACS_YacsLoaderTest|YACS_YacsPMMLExeTest"

pip install pydefx --pre --no-index -f /io/wheelhouse

python -c "import pydefx"

sed -i 's|__testSubDir = "bin/salome/test/yacs"|__testSubDir = "bin/salome/test"|g' /opt/python/${PYTAG}-${ABI}/lib/python${PYVERD}/site-packages/salome/kernel/runTests.py

# cannot run c++ tests since libydefx.so is not mangled
salome test -L YDEFX -VV -E "YDEFX_StudyGeneralTest|YDEFX_StudyRestartTest|YDEFX_SampleTest"
