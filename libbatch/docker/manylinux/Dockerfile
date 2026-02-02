FROM quay.io/pypa/manylinux2014_x86_64

ENV MAKEFLAGS=-j8
WORKDIR /usr/local/src

RUN yum install -y zip tree openssh-server openssh-clients rsh rsh-server rsync

# swig
RUN rm /usr/local/bin/swig*
RUN curl  -fSsL https://github.com/swig/swig/archive/v4.0.2.tar.gz | tar xz && cd swig* \
 && ./autogen.sh && ./configure --without-alllang && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && swig -version && cd - && rm -r swig*
