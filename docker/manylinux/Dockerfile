FROM quay.io/pypa/manylinux2014_x86_64

ENV MAKEFLAGS=-j8
WORKDIR /usr/local/src

RUN yum install -y zip tree openssl-devel libxml2-devel chrpath perl-IPC-Cmd cppunit-devel openssh-server openssh-clients rsh rsh-server rsync gdb vim

# swig
RUN rm /usr/local/bin/swig*
RUN curl  -fSsL https://github.com/swig/swig/archive/v4.0.2.tar.gz | tar xz && cd swig* \
 && ./autogen.sh && ./configure --without-alllang && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && swig -version && cd - && rm -r swig*

# hdf5
RUN curl -fsSL https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.6/hdf5-1.14.6.tar.gz | tar xz && cd hdf5* && ./configure --enable-cxx --prefix=/usr/local --disable-tests --disable-tools --disable-static && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && cd - && rm -r hdf5*

# boost
RUN curl -fSsL https://archives.boost.io/release/1.81.0/source/boost_1_81_0.tar.bz2 | tar xj && cd boost_1_81_0 \
 && ./bootstrap.sh --with-toolset=gcc --with-icu --with-python=/usr/local/bin/python \
 && ./b2 -q variant=release address-model=64 architecture=x86 debug-symbols=off threading=multi runtime-link=shared link=shared toolset=gcc --layout=system ${MAKEFLAGS} install --with-serialization --with-filesystem --with-date_time --with-chrono --with-thread --with-regex --with-system  > /dev/null 2>&1 && cd - && rm -r boost*

# openssl
RUN curl -fSsL https://www.openssl.org/source/openssl-3.3.0.tar.gz | tar xz && cd openssl* \
 && ./config no-shared -fPIC --prefix=/opt/ssl && make depend > /dev/null 2>&1 && make > /dev/null 2>&1 && make install_sw > /dev/null 2>&1

# libffi
RUN curl -fSsL https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz | tar xz && cd libffi* \
 && CFLAGS="-fPIC" ./configure --disable-shared --disable-multi-os-directory --prefix=/opt/ffi && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && cd - && rm -r libffi*

ENV LD_LIBRARY_PATH=/usr/local/lib/
ENV HOME=/root
ENV USER=root

# python (static)
ADD build_static_python.sh /tmp
RUN for pyver in 3.8.20 3.9.21 3.10.16 3.11.11; do /tmp/build_static_python.sh ${pyver}; done

# libbatch
ADD build_libbatch.sh /tmp/
RUN for pyver in cp38 cp39 cp310 cp311; do /tmp/build_libbatch.sh ${pyver}; done

# omniorb
ADD build_omniorb.sh /tmp/
ADD omniorb-noinitfile.patch /tmp
RUN for pyver in cp38 cp39 cp310 cp311; do /tmp/build_omniorb.sh ${pyver}; done

# the patchelf --remove-rpath commands from auditwheel corrupts the executables (ldd crashes)
RUN sed -i "/remove-rpath/d" /opt/_internal/pipx/venvs/auditwheel/lib/python*/site-packages/auditwheel/patcher.py
RUN rm /usr/bin/python
