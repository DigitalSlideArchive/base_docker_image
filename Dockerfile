FROM ubuntu:14.04
MAINTAINER Bilal Salam <bilal.salam@kitware.com>


RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    python-qt4 \
    openslide-tools python-openslide \
    build-essential \
    swig \
    make \
    zlib1g-dev \
    curl \
    libcurl4-openssl-dev \
    libexpat1-dev \
    unzip \
    libhdf5-dev \
    libjpeg-dev \

    libpng12-dev \
    libpython3-dev \
    libtiff5-dev \
    cmake \
    # needed to build openslide, libbtif and openjpg
    # openjpeg
    libglib2.0-dev \
    libjpeg-dev \
    libxml2-dev \
    libpng12-dev \
  # openslide
    autoconf \
    automake \
    libtool \
    pkg-config \
    libcairo2-dev \
    libgdk-pixbuf2.0-dev \
    libxml2-dev \
    libsqlite3-dev &&\
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#manually install openjpg, libtiff and openslide
RUN mkdir build_lib && \
    cd build_lib && \ 
    #build openjpg
    wget -O openjpeg-1.5.2.tar.gz https://github.com/uclouvain/openjpeg/archive/version.1.5.2.tar.gz && \
    tar -zxf openjpeg-1.5.2.tar.gz && \
    cd openjpeg-version.1.5.2 && \
    cmake . && \
    make && \
    sudo make install && \
    sudo ldconfig && \
    cd .. && \

    # Build libtiff so it will use our openjpeg
    wget http://download.osgeo.org/libtiff/tiff-4.0.3.tar.gz && \
    tar -zxf tiff-4.0.3.tar.gz && \
    cd tiff-4.0.3 && \
    ./configure && \
    make && \
    sudo make install && \
    sudo ldconfig && \
    cd .. && \
    

    # Build OpenSlide ourselves so that it will use our libtiff

    wget -O openslide-3.4.1.tar.gz https://github.com/openslide/openslide/archive/v3.4.1.tar.gz && \
    tar -zxf openslide-3.4.1.tar.gz && \
    cd openslide-3.4.1 && \
    autoreconf -i && \
    ./configure && \
    make && \
    sudo make install && \
    sudo ldconfig && \
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
    ninja  && \
    ninja install && \
    cd / && \
    rm -rf ITK ITKbuild 





