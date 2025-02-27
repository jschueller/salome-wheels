
FROM quay.io/pypa/manylinux2014_x86_64
MAINTAINER jschueller

ENV MAKEFLAGS -j8
WORKDIR /usr/local/src

RUN yum install -y zip tree openssl-devel libxml2-devel

# swig
RUN rm /usr/local/bin/swig*
RUN curl  -fSsL https://github.com/swig/swig/archive/v4.0.2.tar.gz | tar xz && cd swig* \
 && ./autogen.sh && ./configure --without-alllang && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && swig -version && cd - && rm -r swig*

# hdf5
RUN curl -fsSL https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.3/src/hdf5-1.10.3.tar.bz2 | tar xj && cd hdf5-1.10.3 && ./configure --enable-cxx --prefix=/usr/local --disable-tests --disable-tools && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && cd - && rm -r hdf5*

# boost
RUN curl -fSsL https://archives.boost.io/release/1.81.0/source/boost_1_81_0.tar.bz2 | tar xj && cd boost_1_81_0 \
 && ./bootstrap.sh --with-toolset=gcc --with-icu --with-python=/usr/local/bin/python \
 && ./b2 -q variant=release address-model=64 architecture=x86 debug-symbols=off threading=multi runtime-link=shared link=shared toolset=gcc --layout=system ${MAKEFLAGS} install --with-serialization --with-filesystem --with-date_time --with-chrono --with-thread --with-regex --with-system  > /dev/null 2>&1 && cd - && rm -r boost*

# openssl
RUN yum install -y perl-IPC-Cmd
RUN curl -fSsL https://www.openssl.org/source/openssl-3.3.0.tar.gz | tar xz && cd openssl* \
 && ./config no-shared -fPIC --prefix=/opt/ssl && make depend > /dev/null 2>&1 && make > /dev/null 2>&1 && make install_sw > /dev/null 2>&1

# libffi
RUN curl -fSsL https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz | tar xz && cd libffi* \
 && CFLAGS="-fPIC" ./configure --disable-shared --disable-multi-os-directory --prefix=/opt/ffi && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && cd - && rm -r libffi*

ADD build_static_python.sh /tmp
RUN /tmp/build_static_python.sh 3.10.16

# temporary build of omniorb/libbatch
ENV OMNIORB_VERSION=4.2.5
ENV PATH=/opt/python/cp310-cp310/bin/:$PATH

RUN curl -L https://downloads.sourceforge.net/omniorb/omniORB-${OMNIORB_VERSION}.tar.bz2|tar xj && cd omniORB* && ./configure --with-openssl=/usr && make && make install
RUN curl -L https://downloads.sourceforge.net/omniorb/omniORBpy/omniORBpy-${OMNIORB_VERSION}/omniORBpy-${OMNIORB_VERSION}.tar.bz2|tar xj && cd omniORBpy* && ./configure --with-omniorb=/usr/local && make && make install
ENV LD_LIBRARY_PATH=/usr/local/lib/ PYTHONPATH=/usr/local/lib/python3.10/site-packages
RUN python -c "from omniORB import CORBA, PortableServer"

ENV LIBBATCH_VERSION=2.5.0
RUN git clone --depth 1 -b V`echo ${LIBBATCH_VERSION}|sed "s|\.|_|g"` https://github.com/SalomePlatform/libbatch.git && cd libbatch && sed -i "s|PYTHON_LIBRARIES|ZZZ|g" src/Python/CMakeLists.txt && cmake -LAH -DCMAKE_BUILD_TYPE=Release \
  -DPYTHON_EXECUTABLE=/opt/python/cp312-cp312/bin/python \
  -DPYTHON_INCLUDE_DIR=/opt/python/cp312-cp312/include/python3.12 -DPYTHON_LIBRARY=dummy \
  -DLIBBATCH_CXX_STANDARD=17 \
  -B build . && cd build && make install
RUN python -c "import libbatch"

# RUN cd /tmp && curl -fSsL https://www.python.org/ftp/python/3.10.16/Python-3.10.16.tgz | tar xz
# RUN grep -nr   forkpty /tmp/Python-3.10.16|grep util
# RUN grep -nr   openpty /tmp/Python-3.10.16|grep util
# RUN cd /tmp/Python-3.10.16 && ./configure ac_cv_func_forkpty=no ac_cv_lib_util_forkpty=no ac_cv_lib_bsd_forkpty=no ac_cv_lib_util_openpty=no|grep openpty
# RUN ldd /opt/python/cp312-cp312/bin/python

# RUN /tmp/build_static_python.sh 3.10.16
