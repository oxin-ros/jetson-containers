#!/usr/bin/env bash

set -x
source scripts/docker_base.sh

PCL_VERSION=${1:-"1.12.1"}
ROS_VERSION=${2:-"melodic"}
BUILD_THREAD_COUNT=${3:-"$(($(nproc)-1))"}

# https://unix.stackexchange.com/questions/285924/how-to-compare-a-programs-version-in-a-shell-script
version_greater_equal()
{
    printf '%s\n%s\n' "$2" "$1" | sort --check=quiet --version-sort
}

build_pcl()
{
    local pcl_version=$1
    local ros_version=$2

    if [ $ARCH = "aarch64" ]; then
        local container_tag="pcl-builder:r$L4T_VERSION-pcl$pcl_version"
        # Only SM_53, SM_62, & SM_72 are built since they correspond to the Jetson devices.
        # See http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards for more info.
        local cuda_arch_bin="53,62,72"
        local base_image=$BASE_IMAGE
        if [ $L4T_RELEASE -eq 32 ]; then # Ubuntu 18.04
            # Check if PCL 1.13 or newer is requrested.
            # Note: the OpenGL backend is depricated in PCL 1.13.
            # The version of VTK for Ubuntu 18.04 aarch64 only supports OpenGL.
            # VTK 7 does support OpenGL2, however it hasn't been published for Ubuntu 18.04 aarch64.
            version_greater_equal $pcl_version "1.13"
            if [ $? -eq 0 ]; then
                echo "PCL v$pcl_version is not supported on Ubuntu 18.04."
                exit 1
            fi

            local vtk_major_version="6"
            local rendering_backend="OpenGL"
        elif [ $L4T_RELEASE -eq 34 ]; then # Ubuntu 20.04
            local vtk_major_version="7"
            local rendering_backend="OpenGL2"
        fi
    elif [ $ARCH = "x86_64" ]; then
        if [ $ros_version = "melodic" ]; then # Ubuntu 18.04
            # Check if PCL 1.13 or newer is requrested.
            # Note: the OpenGL backend is depricated in PCL 1.13.
            # The version of VTK that is used by ROS melodic is VTK 6, which only supports OpenGL.
            version_greater_equal $pcl_version "1.13"
            if [ $? -eq 0 ]; then
                echo "PCL v$pcl_version is not supported on melodic."
                exit 1
            fi

            #
            # ROS Melodic settings compatibile with jetpack.
            #
            local cuda_version="10.2"
            local ubuntu_version="18.04"
            # The version of VTK that is used by ROS melodic is VTK 6.
            local vtk_major_version="6"
            local rendering_backend="OpenGL"
            # CUDA ARCH versions below 50 are to be deprecated from CUDA 11.
            # CUDA ARCH versions above 80 are only supported in CUDA 11 onwards.
            # See http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards for more info.
            local cuda_arch_bin="50;52;53;60;61;62;70;72"
        elif [ $ros_version = "noetic" ]; then
            #
            # ROS Noetic settings compatible with jetpack.
            #
            local cuda_version="11.4.1"
            local ubuntu_version="20.04"
            # VTK 7 supports OpenGL2, but conflicts with VTK 6 packages.
            local vtk_major_version="7"
            local rendering_backend="OpenGL2"
            # CUDA ARCH versions below 50 are to be deprecated from CUDA 11.
            # CUDA ARCH versions above 80 are only supported in CUDA 11 onwards.
            # See http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards for more info.
            local cuda_arch_bin="60;61;62;70;72;80;86"
        fi
        #
        # Container build settings.
        #
        local container_tag="pcl-builder:pcl$pcl_version-cuda$cuda_version-ubuntu$ubuntu_version"
        local base_image="nvcr.io/nvidia/cudagl:$cuda_version-devel-ubuntu$ubuntu_version"
    fi

    echo "building PCL $pcl_version deb packages"

    sh ./scripts/docker_build.sh $container_tag Dockerfile.pcl \
            --build-arg BASE_IMAGE=$base_image \
            --build-arg PCL_VERSION=$pcl_version \
            --build-arg CUDA_ARCH_BIN=$cuda_arch_bin \
            --build-arg VTK_MAJOR_VERSION=$vtk_major_version \
            --build-arg RENDERING_BACKEND=$rendering_backend \
            --build-arg BUILD_THREAD_COUNT=$BUILD_THREAD_COUNT

    if [ $? -ne 0 ]; then
        echo "failed to build PCL v$pcl_version deb packages"
        exit 1
    fi
    echo "done building PCL v$pcl_version deb packages"

    # copy deb packages to jetson-containers/packages directory
    archive_name="pcl-$PCL_VERSION-$ARCH-ubuntu-$ubuntu_version.tar.gz"
    sudo docker run --rm \
            --volume $PWD/packages:/mount \
            $container_tag \
            cp pcl/build/$archive_name /mount

    echo "packages are at $PWD/packages/$archive_name"
}

build_pcl $PCL_VERSION $ROS_VERSION
