#!/bin/sh

set -xe

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
sudo cp -v ~/.ssh/id_ed25519.pub /appdata
echo "waiting for key authorization ..."
sleep 1

ping worker -c 1
ssh-keyscan -t ed25519 -H worker >> ~/.ssh/known_hosts
ssh worker "ls -l /tmp"
ssh worker "ls -l /etc/ssh"
ls -l /etc/ssh

which salome
salome shell -- env
salome shell -- which SALOME_Container

python3 -c "import os; print(os.environ['PATH'])"
python3 -c "import salome.kernel; import os; print(os.environ['PATH'])"

export SALOME_VERBOSE=1
export SALOME_VERBOSE_LEVEL=7

# 1. Test KERNEL basic
python3 /tmp/testProxy.py

# 2. Test YACS DOE
python3 /tmp/testYacs.py

# 3. Test YACS driver mode
cd /tmp
driver --options_from_json=yacs_config.json --activate-custom-overrides PerfTest0.xml

# 4. Test YACS DOE + np.array
python3 /tmp/testYacsComplex.py

# 5. Test YACS DOE + OT objects
python3 /tmp/testYacsComplex2.py

# 6. Test YDEFX
python3 /tmp/testYdefx.py
