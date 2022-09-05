#!/usr/bin/env bash
# this script installs build dependencies for compiling PCL.

set -e -x

ARCH=$(uname -i)
echo "ARCH:  $ARCH"

apt-get update
apt-get install --yes --no-install-recommends \
    apt-utils \
    bash \
    build-essential \
    dirmngr \
    dpkg-dev \
    file \
    g++ \
    git \
    git-all \
    libboost-date-time-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libeigen3-dev \
    libflann-dev \
    libgl1-mesa-dev \
    libglew-dev \
    libgtest-dev \
    liblapack-dev \
    libopenni-dev \
    libopenni2-dev \
    libpcap-dev \
    libproj-dev \
    libqhull-dev \
    libqt5opengl5-dev \
    libusb-1.0-0-dev \
    libvtk6-dev \
    libvtk6-qt-dev \
    libxt-dev \
    qtbase5-dev \
    sudo \
    tar \
    unzip \
    wget 
