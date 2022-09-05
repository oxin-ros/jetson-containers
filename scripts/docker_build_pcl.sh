#!/usr/bin/env bash

set -e
source scripts/docker_base.sh

PCL_VERSION=${1:-"1.12.1"}

build_pcl()
{
    local pcl_version=$1

    if [ $ARCH = "aarch64" ]; then
        local container_tag="pcl-builder:r$L4T_VERSION-pcl$pcl_version"
        local cuda_arch_bin="5.3,6.2,7.2"
    elif [ $ARCH = "x86_64" ]; then
        local container_tag="pcl-builder:pcl$pcl_version"
        local cuda_arch_bin=""
    fi

    echo "building PCL $pcl_version deb packages"

    sh ./scripts/docker_build.sh $container_tag Dockerfile.pcl \
            --build-arg BASE_IMAGE=$BASE_IMAGE \
            --build-arg OPENCV_VERSION=$pcl_version \
            --build-arg CUDA_ARCH_BIN=$cuda_arch_bin 

    echo "done building PCL $pcl_version deb packages"

    # copy deb packages to jetson-containers/packages directory
    sudo docker run --rm \
            --volume $PWD/packages:/mount \
            $container_tag \
            cp pcl/build/PCL-$PCL_VERSION-$ARCH.tar.gz /mount

    echo "packages are at $PWD/packages/PCL-$PCL_VERSION-$ARCH.tar.gz"
}

build_pcl $PCL_VERSION
