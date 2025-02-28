FROM debian:12

RUN apt-get -y update && apt-get -y install python3-pip
RUN pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple pydefx --break-system-packages
RUN python3 -c "import pydefx"
RUN salome shell -- env
