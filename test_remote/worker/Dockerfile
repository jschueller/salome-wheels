FROM debian:11
RUN apt-get update -y && apt-get install openssh-server python3-pip vim -y
RUN pip install pydefx==9.14.0.post5 openturns medcoupling

# FIXME: driver in PATH + SALOME_Container_No_NS_Serv_OutProcess ?
# ENV PATH=/usr/local/lib/python3.9/dist-packages/salome/bin/salome/:$PATH

EXPOSE 22/tcp
ADD entrypoint.sh /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

