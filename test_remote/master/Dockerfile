FROM debian:11
RUN apt-get update -y && apt-get install openssh-client python3-pip iputils-ping sudo -y
RUN pip install pydefx==9.14.0.post6 openturns medcoupling

ADD testProxy.py /tmp/
ADD testYacs.py /tmp/
ADD PerfTest0.xml /tmp/
ADD yacs_config.json /tmp/
ADD yacs_driver_overrides.py /tmp/
ADD testYacsComplex.py /tmp/
ADD testYdefx.py /tmp/

ADD entrypoint.sh /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
