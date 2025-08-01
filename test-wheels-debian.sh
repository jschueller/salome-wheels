#!/bin/bash

set -e -x

test $# = 2 || exit 1

VERSION="$1"
ABI="$2"

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

pip install salome.kernel --pre --no-index -f /io/wheelhouse

python3 -c "import salome.kernel"
python3 -c "from salome.kernel import salome; salome.salome_init()"
python3 -c "import math; import salome.kernel"
python3 -c "import salome.kernel; import math"

which salome
salome shell -- env
salome shell -- which SALOME_Container
salome shell -- ldd /usr/local/lib/python${PYVERD}/dist-packages/salome/bin/salome/SALOME_Container

export SALOME_VERBOSE=1
echo 'import salome.kernel.KernelContainer; import os.path; assert os.path.exists(salome.kernel.KernelContainer.getDftLocOfScripts())' > ensure_scripts_templ.py
salome shell -- python3 ensure_scripts_templ.py


# cd /usr/local/lib/python3.9/dist-packages/salome/bin/salome/test/kernel/Launcher/
# salome shell -- /usr/local/lib/python3.9/dist-packages/salome/bin/salome/appli/python_test_driver.py "2000" "test_launcher.py" || echo "NOPE"
# 
# ls -l /tmp/salome_localres_workdir_root/
# ls -l /tmp/salome_localres_workdir_root/CommandSalomeJob*
# exit 1

# find . -name test_launcher.py
# salome test -L KERNEL -VV -R KERNEL_Launcher -E SWIG

# salome test -L KERNEL -VV -R KERNEL_AttachedLauncher -E SWIG
salome test -L KERNEL -VV -E "KERNEL_LC_LifeCycleCORBA_SWIGTest|KERNEL_LifeCycleCORBA|KERNEL_KernelHelpers|KERNEL_UnitTests"

# pip install salome.yacs --pre --no-index -f /io/wheelhouse
# 
# sed -i 's|__testSubDir = "bin/salome/test/kernel"|__testSubDir = "bin/salome/test/yacs"|g' /usr/local/lib/python${PYVERD}/dist-packages/salome/kernel/runTests.py
# 
# python3 -c "import salome.yacs"
# 
# for subdir in yacsloader yacsloader_swig
# do
#   cp -rv /usr/local/lib/python${PYVERD}/dist-packages/salome/share/salome/yacssamples /usr/local/lib/python${PYVERD}/dist-packages/salome/bin/salome/test/yacs/${subdir}/samples
# done
# 
# # c++ test YACS_YacsPMMLExeTest needs YACS_ROOT_DIR
# salome test -L YACS -VV -E "YACS_YacsRuntimeTest|YACS_YacsLoaderTest|YACS_YacsPMMLExeTest"
# 
# pip install pydefx --pre --no-index -f /io/wheelhouse
# 
# python3 -c "import pydefx"
# 
# sed -i 's|__testSubDir = "bin/salome/test/yacs"|__testSubDir = "bin/salome/test"|g' /usr/local/lib/python${PYVERD}/dist-packages/salome/kernel/runTests.py
# 
# # cannot run c++ tests since libydefx.so is not mangled
# salome test -L YDEFX -VV -E "YDEFX_StudyGeneralTest|YDEFX_StudyRestartTest|YDEFX_SampleTest" SALOME_VERBOSE=1
