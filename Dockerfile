
# SPDX-License-Identifier: BSD 3-Clause License
#
# Copyright (c) 2025, Intel Corporation
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

ARG IMAGE=ubuntu:22.04
FROM $IMAGE AS base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      gpg-agent \
      software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS build
LABEL vendor="Intel Corporation"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
ARG ENABLE_OV_PATCH="false"
ARG OV_VERSION="2024.5"

# openvino
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
      apt-utils \
      ca-certificates \
      curl \
      cmake \
      cython3 \
      flex \
      bison \
      gcc \
      g++ \
      git \
      make \
      patch \
      pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -Lf "https://repositories.intel.com/graphics/intel-graphics.key" -o "intel-graphics.key" && \
    gpg --dearmor --output "/usr/share/keyrings/intel-graphics.gpg" "intel-graphics.key"
RUN echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/graphics/ubuntu jammy flex' | \
    tee "/etc/apt/sources.list.d/intel.gpu.jammy.list"

# clone ivsr repo
ARG WORKSPACE=/workspace
ARG IVSR_DIR=${WORKSPACE}/ivsr
ARG IVSR_REPO=https://github.com/OpenVisualCloud/iVSR.git
ARG IVSR_VERSION=v25.03

WORKDIR ${IVSR_DIR}
RUN git clone ${IVSR_REPO} ${IVSR_DIR} && \
    git checkout ${IVSR_VERSION}

#install opencv
ARG OPENCV_REPO=https://github.com/opencv/opencv/archive/4.5.3-openvino-2021.4.2.tar.gz
WORKDIR ${WORKSPACE}
RUN curl -Lf "${OPENCV_REPO}" -o "4.5.3-openvino-2021.4.2.tar.gz" && \
    tar xzf "4.5.3-openvino-2021.4.2.tar.gz" && \
    rm -f "4.5.3-openvino-2021.4.2.tar.gz"

WORKDIR "${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/build"
RUN mkdir -p "${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install" && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DOPENCV_GENERATE_PKGCONFIG=ON \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DBUILD_TESTS=OFF \
      -DWITH_OPENEXR=OFF \
      -DWITH_OPENJPEG=OFF \
      -DWITH_GSTREAMER=OFF \
      -DWITH_JASPER=OFF \
      .. && \
    make -j "$(nproc)" && \
    make install

WORKDIR ${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install/bin
RUN bash ./setup_vars_opencv4.sh

RUN if [ "$OV_VERSION" = "2022.3" ]; then \
        apt-get update; \
        xargs apt-get install -y --no-install-recommends --fix-missing < ${IVSR_DIR}/ivsr_sdk/dgpu_umd_stable_555_0124.txt; \
        apt-get install -y --no-install-recommends vainfo clinfo; \
        apt-get clean; \
        rm -rf  /var/lib/apt/lists/*; \
    fi

WORKDIR /tmp/gpu_deps
RUN if [ "$OV_VERSION" = "2023.2" ] || [ "$OV_VERSION" = "2024.5" ]; then \
      # for GPU
      apt-get update; \
      apt-get install -y --no-install-recommends vainfo clinfo; \
      apt-get install -y --no-install-recommends ocl-icd-libopencl1; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*; \
    fi
WORKDIR /tmp/gpu_deps
RUN if [ "$OV_VERSION" = "2023.2" ]; then \
      # hadolint ignore=DL3003
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.05.25593.11/libigdgmm12_22.3.0_amd64.deb; \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-core_1.0.13700.14_amd64.deb; \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-opencl_1.0.13700.14_amd64.deb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-opencl-icd_23.13.26032.30_amd64.deb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/libigdgmm12_22.3.0_amd64.deb; \
      dpkg -i ./*.deb && rm -Rf /tmp/gpu_deps; \
    fi

WORKDIR /tmp/gpu_deps
RUN if [ "$OV_VERSION" = "2024.5" ]; then \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-core_1.0.17384.11_amd64.deb; \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-opencl_1.0.17384.11_amd64.deb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-level-zero-gpu-dbgsym_1.3.30508.7_amd64.ddeb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-level-zero-gpu_1.3.30508.7_amd64.deb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-opencl-icd-dbgsym_24.31.30508.7_amd64.ddeb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-opencl-icd_24.31.30508.7_amd64.deb; \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/libigdgmm12_22.4.1_amd64.deb; \
      dpkg -i ./*.deb && rm -Rf /tmp/gpu_deps; \
    fi
ENV LD_LIBRARY_PATH=${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install/lib
ENV OpenCV_DIR=${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install/lib/cmake/opencv4
ARG IVSR_OV_DIR=${IVSR_DIR}/ivsr_ov/based_on_openvino_${OV_VERSION}/openvino
ARG CUSTOM_OV_INSTALL_DIR=${IVSR_OV_DIR}/install
ARG IVSR_SDK_DIR=${IVSR_DIR}/ivsr_sdk
ARG PYTHON=python3.10

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      cmake \
      cython3 \
      flex \
      bison \
      gcc \
      g++ \
      git \
      libdrm-dev \
      libudev-dev \
      libtool \
      libusb-1.0-0-dev \
      make \
      patch \
      pkg-config \
      xz-utils \
      ocl-icd-opencl-dev \
      opencl-headers && \
    apt-get install -y --no-install-recommends --fix-missing \
      ${PYTHON} \
      lib${PYTHON}-dev \
      python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip --no-cache-dir install --upgrade \
      pip \
      setuptools && \
    ln -sf "$(which "${PYTHON}")" /usr/local/bin/python && \
    ln -sf "$(which "${PYTHON}")" /usr/local/bin/python3 && \
    ln -sf "$(which "${PYTHON}")" /usr/bin/python && \
    ln -sf "$(which "${PYTHON}")" /usr/bin/python3

    ARG OV_REPO=https://github.com/openvinotoolkit/openvino.git
    ARG OV_BRANCH=${OV_VERSION}.0
    WORKDIR ${IVSR_OV_DIR}

    RUN git config --global user.email "noname@example.com" && \
        git config --global user.name "no name" && \
        git clone ${OV_REPO} ${IVSR_OV_DIR} && \
        git checkout ${OV_BRANCH} && \
        git submodule update --init --recursive

    RUN if [ "$ENABLE_OV_PATCH" = "true" ] && [ "$OV_VERSION" = "2022.3" ]; then \
            { set -e; \
              for patch_file in $(find ../patches -iname "*.patch" | sort -n); do \
                echo "Applying: ${patch_file}"; \
                git am --whitespace=fix ${patch_file}; \
              done; }; \
        fi

    WORKDIR ${IVSR_DIR}/ivsr_ov/based_on_openvino_${OV_VERSION}
    RUN mkdir -p openvino/build && \
        cd openvino/build && \
        cmake \
          -DCMAKE_INSTALL_PREFIX="${PWD}/../install" \
          -DENABLE_INTEL_CPU=ON \
          -DENABLE_CLDNN=ON \
          -DENABLE_INTEL_GPU=ON \
          -DENABLE_ONEDNN_FOR_GPU=OFF \
          -DENABLE_INTEL_GNA=OFF \
          -DENABLE_INTEL_MYRIAD_COMMON=OFF \
          -DENABLE_INTEL_MYRIAD=OFF \
          -DENABLE_PYTHON=ON \
          -DENABLE_OPENCV=ON \
          -DENABLE_SAMPLES=ON \
          -DENABLE_CPPLINT=OFF \
          -DTREAT_WARNING_AS_ERROR=OFF \
          -DENABLE_TESTS=OFF \
          -DENABLE_GAPI_TESTS=OFF \
          -DENABLE_BEH_TESTS=OFF \
          -DENABLE_FUNCTIONAL_TESTS=OFF \
          -DENABLE_OV_CORE_UNIT_TESTS=OFF \
          -DENABLE_OV_CORE_BACKEND_UNIT_TESTS=OFF \
          -DENABLE_DEBUG_CAPS=ON \
          -DENABLE_GPU_DEBUG_CAPS=ON \
          -DENABLE_CPU_DEBUG_CAPS=ON \
          -DCMAKE_BUILD_TYPE=Release \
          .. && \
        make -j $(nproc) && \
        make install && \
        bash "${PWD}/../install/setupvars.sh" && \
        install ${IVSR_OV_DIR}/install/runtime/3rdparty/tbb/lib/* /usr/local/lib && \
        install ${IVSR_OV_DIR}/install/runtime/lib/intel64/* /usr/local/lib && \
        install /workspace/opencv-4.5.3-openvino-2021.4.2/install/lib/* /usr/local/lib && \
        install /workspace/opencv-4.5.3-openvino-2021.4.2/install/bin/* /usr/local/bin && \
        mv "${IVSR_OV_DIR}/install" "/workspace/ivsr_ov-openvino-${OV_VERSION}" && \
        cd ../.. && \
        rm -rf "${IVSR_OV_DIR}" || true

    ARG CUSTOM_IE_DIR=${CUSTOM_OV_INSTALL_DIR}/runtime
    ARG CUSTOM_IE_LIBDIR=${CUSTOM_IE_DIR}/lib/intel64
    ARG CUSTOM_OV=${CUSTOM_IE_DIR}

    ENV OpenVINO_DIR=${CUSTOM_IE_DIR}/cmake
    ENV InferenceEngine_DIR=${CUSTOM_IE_DIR}/cmake
    ENV TBB_DIR=${CUSTOM_IE_DIR}/3rdparty/tbb/cmake
    ENV ngraph_DIR=${CUSTOM_IE_DIR}/cmake
    ENV LD_LIBRARY_PATH=${CUSTOM_IE_DIR}/3rdparty/tbb/lib:${CUSTOM_IE_LIBDIR}:$LD_LIBRARY_PATH

    WORKDIR ${IVSR_SDK_DIR}/build
    RUN cmake .. \
          -DENABLE_LOG=OFF -DENABLE_PERF=OFF -DENABLE_THREADPROCESS=ON \
          -DCMAKE_BUILD_TYPE=Release && \
        make -j $(nproc) && \
        make install && \
        echo "Building vsr sdk finished."

# build raisr
# install 3rd-party libraries required by raisr and raisr
WORKDIR ${WORKSPACE}
RUN curl -Lf "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/7e07b203-af56-4b52-b69d-97680826a8df/l_ipp_oneapi_p_2021.12.1.16_offline.sh" -o "l_ipp_oneapi_p_2021.12.1.16_offline.sh" && \
    chmod +x ./l_ipp_oneapi_p_2021.12.1.16_offline.sh && \
    ./l_ipp_oneapi_p_2021.12.1.16_offline.sh -a -s --eula accept && \
    source  /opt/intel/oneapi/ipp/latest/env/vars.sh && \
    rm ./l_ipp_oneapi_p_2021.12.1.16_offline.sh

ENV LD_LIBRARY_PATH=/opt/intel/oneapi/ipp/2021.12/lib:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=/opt/intel/oneapi/ipp/2021.12/lib
ENV IPPROOT=/opt/intel/oneapi/ipp/2021.12
ENV CMAKE_PREFIX_PATH=/opt/intel/oneapi/ipp/2021.12/lib/cmake/ipp
ARG RAISR_REPO=https://github.com/OpenVisualCloud/Video-Super-Resolution-Library.git
ARG RAISR_BRANCH=v23.11.1
ARG RAISR_DIR=${WORKSPACE}/raisr

WORKDIR ${RAISR_DIR}
RUN git clone ${RAISR_REPO} ${RAISR_DIR} && \
    git checkout ${RAISR_BRANCH}

RUN  ./build.sh -DENABLE_RAISR_OPENCL=ON

#build ffmpeg with iVSR SDK backend and raisr
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      tar \
      g++ \
      wget \
      pkg-config \
      nasm \
      yasm \
      libglib2.0-dev \
      flex \
      bison \
      gobject-introspection \
      libgirepository1.0-dev \
      python3-dev \
      libx11-dev \
      libxv-dev \
      libxt-dev \
      libasound2-dev \
      libpango1.0-dev \
      libtheora-dev \
      libvisual-0.4-dev \
      libgl1-mesa-dev \
      libcurl4-gnutls-dev \
      librtmp-dev \
      mjpegtools \
      libx264-dev \
      libx265-dev \
      libde265-dev \
      libva-dev && \
    rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH=${IVSR_SDK_DIR}/lib:/usr/local/lib:$LD_LIBRARY_PATH
ENV C_INCLUDE_PATH="/opt/intel/oneapi/ipp/latest/include/ipp"

ARG FFMPEG_DIR=${WORKSPACE}/ffmpeg

ARG FFMPEG_REPO=https://github.com/FFmpeg/FFmpeg.git
ARG FFMPEG_VERSION=n7.1
WORKDIR ${FFMPEG_DIR}
RUN git clone ${FFMPEG_REPO} ${FFMPEG_DIR} && \
    git checkout ${FFMPEG_VERSION}

RUN cp ${IVSR_DIR}/ivsr_ffmpeg_plugin/patches/*.patch ${FFMPEG_DIR}/
# apply patches of ivsr ffmpeg
RUN { set -e; \
  for patch_file in $(find -iname "*.patch" | sort -n); do \
    echo "Applying: ${patch_file}"; \
    git am --whitespace=fix ${patch_file}; \
  done; }

# apply patches of raisr ffmpeg
COPY ./patches/* ${FFMPEG_DIR}/
RUN git -C "${FFMPEG_DIR}" am "${FFMPEG_DIR}/0001-Upgrade-Raisr-ffmpeg-plugin-to-n7.1-from-n6.1.1.patch" && \
    cp -r "${RAISR_DIR}/filters_2x" /filters_2x && \
    cp -r "${RAISR_DIR}/filters_1.5x" /filters_1.5x

ARG PREFIX="/install"
RUN if [ -f "${CUSTOM_OV_INSTALL_DIR}/setvars.sh" ]; then \
      . "${CUSTOM_OV_INSTALL_DIR}/setvars.sh" ; \
    fi && \
    export LD_LIBRARY_PATH="${IVSR_SDK_DIR}/lib:${CUSTOM_IE_LIBDIR}:${TBB_DIR}/../lib:${LD_LIBRARY_PATH}" && \
    ./configure \
    --extra-cflags=-fopenmp \
    --extra-ldflags=-fopenmp \
    --disable-shared \
    --enable-libivsr \
    --enable-static \
    --disable-doc \
    --enable-shared \
    --enable-vaapi \
    --enable-gpl \
    --enable-libx264 \
    --enable-libx265 \
    --enable-version3 \
    --enable-libipp \
    --enable-opencl \
    --extra-libs='-lraisr -lstdc++ -lippcore -lippvm -lipps -lippi -lm' \
    --enable-cross-compile \
    --prefix="${PREFIX}" && \
    make -j "$(nproc)" && \
    make install

WORKDIR ${PREFIX}
RUN mkdir -p "${PREFIX}/usr/lib" "${PREFIX}/usr/local" && \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PREFIX}/lib" "${PREFIX}/bin/ffmpeg" -buildconf && \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PREFIX}/lib" ldd "${PREFIX}/bin/ffmpeg" | cut -d ' ' -f 3 | xargs -i cp {} "${PREFIX}/usr/lib" && \
    LD_LIBRARY_PATH="/opt/intel/oneapi/ipp/latest/lib:${PREFIX}/usr/lib" "${PREFIX}/bin/ffmpeg" -buildconf && \
    mv "${PREFIX}/bin" "${PREFIX}/usr/bin" && \
    mv "${PREFIX}/lib" "${PREFIX}/usr/local/"

FROM ubuntu:22.04@sha256:67cadaff1dca187079fce41360d5a7eb6f7dcd3745e53c79ad5efd8563118240 AS runtime

LABEL org.opencontainers.image.authors="jerry.dong@intel.com,xiaoxia.liang@intel.com,milosz.linkiewicz@intel.com"
LABEL org.opencontainers.image.url="https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite"
LABEL org.opencontainers.image.title="Intel® Media & Entertainment AI Suite"
LABEL org.opencontainers.image.description="Intel® Media & Entertainment AI Suite with OpenCL for RAISR (Rapid and Accurate Image Super Resolution) and iVCR, as FFmpeg plugin. Ubuntu 22.04 Docker image."
LABEL org.opencontainers.image.documentation="https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/blob/main/README.md"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Intel® Corporation"
LABEL org.opencontainers.image.licenses="BSD 3-Clause License"

ENV LD_LIBRARY_PATH="/opt/intel/oneapi/ipp/latest/lib:/usr/local/lib:/usr/local/lib64:/usr/lib"
ENV LIBVA_DRIVERS_PATH=/usr/local/lib/dri
ARG OV_VERSION="2024.5"

SHELL ["/bin/bash", "-ex", "-o", "pipefail", "-c"]

WORKDIR /opt/intel_ai_suite
RUN apt-get update --fix-missing && \
    apt-get full-upgrade -y && \
    apt-get install --no-install-recommends -y \
      sudo \
      curl \
      ca-certificates \
      gpg \
      libx264-1* \
      libx265-1* \
      unzip \
      libpcre3 \
      libpcre3-dev \
      libssl-dev \
      gcc \
      zlib1g-dev \
      make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 2110 vfio && \
    groupadd -g 13000 ivsr && \
    useradd -m -s /bin/bash -G vfio -g ivsr -u 13000 ivsr && \
    usermod -aG sudo ivsr && \
    passwd -d ivsr

RUN curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null && \
    curl -fsSL https://repositories.intel.com/graphics/intel-graphics.key | gpg --dearmor | tee /usr/share/keyrings/intel-graphics-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/intel-oneAPI.list && \
    echo "deb [signed-by=/usr/share/keyrings/intel-graphics-archive-keyring.gpg arch=amd64] https://repositories.intel.com/graphics/ubuntu jammy flex" > /etc/apt/sources.list.d/intel-graphics.list && \
    apt-get update --fix-missing && \
    apt-get install --no-install-recommends -y \
      intel-opencl-icd \
      intel-level-zero-gpu \
      intel-oneapi-ipp-2021.12 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build --chown=ivsr:ivsr /install /
COPY --from=build --chown=ivsr:ivsr /workspace/ivsr/ivsr_ov/based_on_openvino_${OV_VERSION}/openvino/install/runtime/3rdparty/tbb/lib/* /usr/local/lib
COPY --from=build --chown=ivsr:ivsr /workspace/ivsr/ivsr_ov/based_on_openvino_${OV_VERSION}/openvino/install/runtime/lib/intel64/* /usr/local/lib
COPY --from=build --chown=ivsr:ivsr /workspace/opencv-4.5.3-openvino-2021.4.2/install/lib/* /usr/local/lib
COPY --from=build --chown=ivsr:ivsr /workspace/opencv-4.5.3-openvino-2021.4.2/install/bin/* /usr/local/lib
COPY --from=build --chown=ivsr:ivsr /workspace/raisr/filters_1.5x /filters_1.5x
COPY --from=build --chown=ivsr:ivsr /workspace/raisr/filters_2x /filters_2x

RUN ln -s /usr/bin/ffmpeg /opt/intel_ai_suite/ffmpeg && \
    ldconfig  && \
    ffmpeg -buildconf && \
    ffmpeg -h filter=raisr

USER "ivsr"

SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "/opt/intel_ai_suite/ffmpeg" ]
HEALTHCHECK --interval=30s --timeout=5s CMD ps aux | grep "ffmpeg" || exit 1
