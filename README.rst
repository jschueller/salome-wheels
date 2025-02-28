salome-wheels
=============

Scripts to build SALOME Python wheels.

Build the wheels::

    ./build_locally.sh

This will create the wheel into a /wheelhouse subdirectory.

Upload the wheels on test.PyPI repository::

    ./upload-pypi.sh

It assumes you have an account on PyPI with access to the different salome wheels projects,
and configured a .pypirc configuration file with your access tokens.

Additional tests make sure we can load everything from PyPI for Debian targets::

    ./test-wheels-debian.sh

Then the wheels can be published on PyPI repository (modify the repo in the script)::

    ./upload-pypi.sh

Finally the wheels can be installed using::

    pip install pydefx

Checkout the relevant projects on PyPI:

- https://pypi.org/project/salome-omniorb
- https://pypi.org/project/libbatch
- https://pypi.org/project/salome.kernel
- https://pypi.org/project/salome.yacs
- https://pypi.org/project/pydefx

