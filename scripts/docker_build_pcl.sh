#!/usr/bin/env bash

set -e
source scripts/docker_base.sh

PCL_VERSION=${1:-"1.12.1"}

build_pcl()
{
    local pcl_version=$1

    if [ $ARCH = "aarch64" ]; then
        local container_tag="pcl-builder:r$L4T_VERSION-pcl$pcl_version"
        # Only SM_53, SM_62, & SM_72 are built since they correspond to the Jetson devices.
        # See http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards for more info.
        local cuda_arch_bin="53,62,72"
        local base_image=$BASE_IMAGE
        if [ $L4T_RELEASE -eq 32 ]; then
            # NOTE: the OpenGL backend is planned to be depricated in PCL 1.13.
            # The version of VTK for Ubuntu 18.04 aarch64 only supports OpenGL.
            # VTK 7 does support OpenGL2, however it hasn't been published for Ubuntu 18.04 aarch64.
            local vtk_major_version="6"
            local rendering_backend="OpenGL"
        elif [ $L4T_RELEASE -eq 34 ]; then # Ubuntu 20.04
            local vtk_major_version="7"
            local rendering_backend="OpenGL2"
        fi
    elif [ $ARCH = "x86_64" ]; then
        local container_tag="pcl-builder:pcl$pcl_version"
        # CUDA ARCH versions below 50 are to be deprecated from CUDA 11.
        # CUDA ARCH versions above 80 are only supported in CUDA 11 onwards.
        local cuda_arch_bin="50;52;53;60;61;62;70;72"
        local base_image="nvcr.io/nvidia/cudagl:10.2-devel-ubuntu18.04"
        local vtk_major_version="7"
        local rendering_backend="OpenGL2"
    fi

    echo "building PCL $pcl_version deb packages"

    sh ./scripts/docker_build.sh $container_tag Dockerfile.pcl \
            --build-arg BASE_IMAGE=$base_image \
            --build-arg PCL_VERSION=$pcl_version \
            --build-arg CUDA_ARCH_BIN=$cuda_arch_bin \
            --build-arg VTK_MAJOR_VERSION=$vtk_major_version \
            --build-arg RENDERING_BACKEND=$rendering_backend

    echo "done building PCL $pcl_version deb packages"

    # copy deb packages to jetson-containers/packages directory
    sudo docker run --rm \
            --volume $PWD/packages:/mount \
            $container_tag \
            cp pcl/build/PCL-$PCL_VERSION-$ARCH.tar.gz /mount

    echo "packages are at $PWD/packages/PCL-$PCL_VERSION-$ARCH.tar.gz"
}

build_pcl $PCL_VERSION
