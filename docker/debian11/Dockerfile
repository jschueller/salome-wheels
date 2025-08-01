FROM debian:11

RUN apt-get -y update && apt-get install -y python3-pip cmake rsync openssh-server rsh-server -y
ENV HOME=/root
ENV USER=root
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN pip install "numpy<2" "psutil<6" packaging
RUN ln -sf /bin/bash /bin/sh
RUN ln -s /usr/bin/python3 /usr/bin/python

