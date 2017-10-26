FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER MAINTAINER David Manthey <david.manthey@kitware.com>


RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    python-qt4 \
    # openslide-tools \
    # python-openslide \
    # swig \
    # make \
    curl \
    ca-certificates \
    libcurl4-openssl-dev \
    libexpat1-dev \
    unzip \
    libhdf5-dev \
    libpython3-dev \
    python2.7-dev \
    python-software-properties \
    libssl-dev \

    # needed to build openslide, libtif and openjpg
    build-essential \
    cmake \
    libtiff5-dev \
    libjpeg8-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    tcl8.6-dev \
    tk8.6-dev \
    python-tk \
    libvips-tools \
    libglib2.0-dev \
    libjpeg-dev \
    libxml2-dev \
    libpng12-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libcairo2-dev \
    libgdk-pixbuf2.0-dev \
    libsqlite3-dev \

    libjpeg-turbo8-dev \

    # needed for supporting CUDA
    libcupti-dev \

    # useful later
    libmemcached-dev && \

    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /

# build our own openjpg, libtiff and openslide.  Do this as one Docker command
# so that the intermediate images are small
RUN mkdir build_lib && \

    #build openjpg
    cd /build_lib && \
    wget -O openjpeg-2.1.2.tar.gz https://github.com/uclouvain/openjpeg/archive/v2.1.2.tar.gz && \
    tar -zxf openjpeg-2.1.2.tar.gz && \
    cd openjpeg-2.1.2 && \
    cmake . && \
    make && \
    make install && \
    ldconfig && \

    # Build libtiff so it will use our openjpeg
    cd /build_lib && \
    wget http://download.osgeo.org/libtiff/tiff-4.0.6.tar.gz && \
    tar -zxf tiff-4.0.6.tar.gz && \
    cd tiff-4.0.6 && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \

    # Build OpenSlide ourselves so that it will use our libtiff
    cd /build_lib && \
    wget -O openslide-3.4.1.tar.gz https://github.com/openslide/openslide/archive/v3.4.1.tar.gz && \
    tar -zxf openslide-3.4.1.tar.gz && \
    cd openslide-3.4.1 && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \

    cd / && \
    rm -rf build_lib

WORKDIR /

# Install miniconda
ENV build_path=$PWD/build
RUN mkdir -p $build_path && \
    wget https://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh \
    -O $build_path/install_miniconda.sh && \
    bash $build_path/install_miniconda.sh -b -p $build_path/miniconda && \
    rm $build_path/install_miniconda.sh && \
    chmod -R +r $build_path && \
    chmod +x $build_path/miniconda/bin/python
ENV PATH=$build_path/miniconda/bin:${PATH}


#ITK dependencies

RUN cd / && \
    mkdir ninja && \
    cd ninja && \
    wget https://github.com/ninja-build/ninja/releases/download/v1.7.1/ninja-linux.zip && \
    unzip ninja-linux.zip && \
    ln -s $(pwd)/ninja /usr/bin/ninja


#need to get the latest tag of master branch in ITK
# v4.10.0 = 95291c32dc0162d688b242deea2b059dac58754a
RUN cd / && \
    git clone https://github.com/InsightSoftwareConsortium/ITK.git && \
    cd ITK && \
    git checkout $(git describe --abbrev=0 --tags) && \
    #now get openslide
    cd Modules/External && \
    git clone https://github.com/InsightSoftwareConsortium/ITKIOOpenSlide.git && \
    cd / && \
    mkdir ITKbuild && \
    cd ITKbuild && \
    cmake \
        -G Ninja \
        -DITK_USE_SYSTEM_SWIG:BOOL=OFF \
        -DBUILD_EXAMPLES:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
        -DITK_LEGACY_REMOVE:BOOL=ON \
        -DITK_BUILD_DEFAULT_MODULES:BOOL=ON \
        -DITK_USE_SYSTEM_LIBRARIES:BOOL=ON \
        -DModule_ITKIOImageBase:BOOL=ON \
        -DModule_ITKSmoothing:BOOL=ON \
        -DModule_ITKTestKernel:BOOL=ON \
        -DModule_IOOpenSlide:BOOL=ON \
        -DCMAKE_INSTALL_PREFIX:PATH=/build/miniconda \
        -DITK_WRAP_PYTHON=ON \
        -DPYTHON_INCLUDE_DIR:FILEPATH=/build/miniconda/include/python2.7 \
        -DPYTHON_LIBRARY:FILEPATH=/build/miniconda/lib/libpython2.7.so \
        -DPYTHON_EXECUTABLE:FILEPATH=/build/miniconda/bin/python \
        -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_TESTING:BOOL=OFF ../ITK && \
    ninja && \
    ninja install && \
    cd / && \
    rm -rf ITK ITKbuild

