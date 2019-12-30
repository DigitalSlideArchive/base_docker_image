# FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
FROM nvidia/cuda:9.2-cudnn7-devel-ubuntu18.04
LABEL maintainer="Kitware, Inc. <kitware@kitware.com>"

RUN apt-get update && \
    apt-get install --yes --no-install-recommends software-properties-common && \
    # As of 2018-04-16 this repo has the latest release of Python 2.7 (2.7.14) \
    # add-apt-repository ppa:jonathonf/python-2.7 && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --yes --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    wget \
    python-qt4 \
    python3-pyqt4 \
    curl \
    ca-certificates \
    libcurl4-openssl-dev \
    libexpat1-dev \
    unzip \
    libhdf5-dev \
    libpython-dev \
    libpython3-dev \
    python2.7-dev \
    python-tk \
    python3.6-dev \
    python3.6-distutils \
    python3-tk \
    software-properties-common \
    libssl-dev \
    # needed to build openslide, libtif and openjpg \
    # libopenslide-dev \
    # libtiff-dev \
    # libvips-dev \
    # Standard build tools \
    build-essential \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # needed for supporting CUDA \
    libcupti-dev \
    # Needed for ITK and SlicerExecutionModel \
    # ninja-build \
    \
    # useful later \
    libmemcached-dev && \
    \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /
# Make Python3 the default and install pip.  Whichever is done last determines
# the default python version for pip.
RUN rm /usr/bin/python && \
    ln /usr/bin/python3 /usr/bin/python
RUN curl https://bootstrap.pypa.io/get-pip.py -O && \
    python2 get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

ENV build_path=$PWD/build
