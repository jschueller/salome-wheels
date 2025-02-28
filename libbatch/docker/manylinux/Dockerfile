
FROM quay.io/pypa/manylinux2014_x86_64
MAINTAINER jschueller

ENV MAKEFLAGS -j8
WORKDIR /usr/local/src

RUN yum install -y zip tree

# swig
RUN rm /usr/local/bin/swig*
RUN curl  -fSsL https://github.com/swig/swig/archive/v4.0.2.tar.gz | tar xz && cd swig* \
 && ./autogen.sh && ./configure --without-alllang && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && swig -version && cd - && rm -r swig*

# openssl
#RUN yum install -y perl-IPC-Cmd
#RUN curl -fSsL https://www.openssl.org/source/openssl-3.3.0.tar.gz | tar xz && cd openssl* \
# && ./config no-shared -fPIC --prefix=/opt/ssl && make depend > /dev/null 2>&1 && make > /dev/null 2>&1 && make install_sw > /dev/null 2>&1

# libffi
#RUN curl -fSsL https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz | tar xz && cd libffi* \
# && CFLAGS="-fPIC" ./configure --disable-shared --disable-multi-os-directory --prefix=/opt/ffi && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && cd - && rm -r libffi*

#ADD build_static_python.sh /tmp
#RUN /tmp/build_static_python.sh 3.12.8

