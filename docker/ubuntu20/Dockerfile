FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && apt-get install -y python-is-python3 python3-pip cmake rsync openssh-server rsh-server -y
ENV HOME=/root
ENV USER=root
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN pip install "numpy<2" "psutil<6" packaging
