# syntax=docker/dockerfile:1

# Copyright (c) 2020-2023 Intel Corporation.
# SPDX-License-Identifier: BSD-3-Clause

ARG IMAGE_CACHE_REGISTRY=docker.io
FROM "${IMAGE_CACHE_REGISTRY}/library/ubuntu:22.04@sha256:67cadaff1dca187079fce41360d5a7eb6f7dcd3745e53c79ad5efd8563118240" AS build-stage

ENV DEBIAN_FRONTEND="noninteractive"
ENV WORKSPACE="/workspace"
# For use with DESTDIR=${INSTALL_PREFIX} make install
ENV INSTALL_PREFIX="/install"

ARG PYTHON=python3.10
ARG ENABLE_OV_PATCH="false"
ARG OV_VERSION="2024.5"
ARG IVSR_REPO="https://github.com/OpenVisualCloud/iVSR"
ARG IVSR_VERSION="v25.03"
ARG OPENCV_REPO="https://github.com/opencv/opencv"
ARG OPENCV_VERSION="4.5.3-openvino-2021.4.2"
ARG OV_REPO=https://github.com/openvinotoolkit/openvino.git
ARG OV_BRANCH="${OV_VERSION}.0"
ARG RAISR_REPO="https://github.com/OpenVisualCloud/Video-Super-Resolution-Library"
ARG RAISR_BRANCH="v23.11.1"
ARG FFMPEG_REPO="https://github.com/FFmpeg/FFmpeg"
ARG FFMPEG_VERSION="n7.1"

ENV IVSR_DIR="${WORKSPACE}/ivsr"
ENV OPENCV_DIR="${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2"
ENV BASED_ON_OPENVINO_DIR="${IVSR_DIR}/ivsr_ov/based_on_openvino_${OV_VERSION}"
ENV IVSR_OV_DIR="${BASED_ON_OPENVINO_DIR}/openvino"
ENV IVSR_SDK_DIR="${IVSR_DIR}/ivsr_sdk"
ENV RAISR_DIR="${WORKSPACE}/raisr"
ENV FFMPEG_DIR="${WORKSPACE}/ffmpeg"

COPY scripts/common.sh /opt/intel/common.sh
COPY patches/* /opt/intel/ffmpeg/patches/

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
WORKDIR "${WORKSPACE}"
RUN apt-get update --fix-missing && \
    apt-get full-upgrade -y && \
    apt-get install --no-install-recommends -y \
      curl \
      ca-certificates \
      gpg-agent \
      software-properties-common \
      apt-utils \
      cython3 \
      flex \
      bison \
      patch \
      cmake \
      nasm \
      build-essential \
      pkg-config \
      less \
      yasm && \
    curl -fsSL "https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB" | gpg --dearmor > "/usr/share/keyrings/intel-oneapi.gpg" && \
    curl -fsSL "https://repositories.intel.com/graphics/intel-graphics.key" | gpg --dearmor > "/usr/share/keyrings/intel-gpu.gpg" && \
    echo "deb [signed-by=/usr/share/keyrings/intel-oneapi.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/intel-oneAPI.list && \
    echo "deb [signed-by=/usr/share/keyrings/intel-gpu.gpg arch=amd64] https://repositories.intel.com/graphics/ubuntu jammy flex" > /etc/apt/sources.list.d/intel-graphics.list && \
    apt-get clean && \
    rm -rf intel-graphics.key /var/lib/apt/lists/*

RUN apt-get update --fix-missing && \
    apt-get install --no-install-recommends -y \
      intel-oneapi-ipp-devel-2022.0 \
      intel-opencl-icd \
      intel-level-zero-gpu \
      ocl-icd-opencl-dev \
      opencl-headers \
      libdrm-dev \
      libudev-dev \
      libtool \
      vainfo \
      clinfo && \
    source /opt/intel/common.sh && \
    git_repo_download_strip_unpack "${IVSR_REPO}" "refs/tags/${IVSR_VERSION}" "${IVSR_DIR}" && \
    git_repo_download_strip_unpack "${OPENCV_REPO}" "${OPENCV_VERSION}" "${OPENCV_DIR}" && \
    apt-get clean && \
    rm -rf intel-graphics.key /var/lib/apt/lists/*

WORKDIR "${OPENCV_DIR}/build"
RUN mkdir -p "${OPENCV_DIR}/install" && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${OPENCV_DIR}/install" \
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
    make install -j "$(nproc)" && \
    DESTDIR=${INSTALL_PREFIX} make install -j "$(nproc)"

WORKDIR "${OPENCV_DIR}/install/bin"
RUN bash ./setup_vars_opencv4.sh

RUN if [ "$OV_VERSION" = "2022.3" ]; then \
        apt-get update; \
        xargs apt-get install -y --no-install-recommends --fix-missing < ${IVSR_DIR}/ivsr_sdk/dgpu_umd_stable_555_0124.txt; \
        apt-get clean; \
        rm -rf  /var/lib/apt/lists/*; \
    fi

WORKDIR /tmp/gpu_deps
RUN if [ "$OV_VERSION" = "2023.2" ] || [ "$OV_VERSION" = "2024.5" ]; then \
      # for GPU
      apt-get update; \
      apt-get install -y --no-install-recommends ocl-icd-libopencl1; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*; \
    fi
WORKDIR /tmp/gpu_deps
RUN if [ "$OV_VERSION" = "2023.2" ]; then \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-core_1.0.13700.14_amd64.deb && \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-opencl_1.0.13700.14_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-opencl-icd_23.13.26032.30_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-level-zero-gpu_1.3.26032.30_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/libigdgmm12_22.3.0_amd64.deb; \
    fi && \
    if [ "$OV_VERSION" = "2024.5" ]; then \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-core_1.0.17384.11_amd64.deb && \
      curl -L -O https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17384.11/intel-igc-opencl_1.0.17384.11_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-level-zero-gpu_1.3.30508.7_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/intel-opencl-icd_24.31.30508.7_amd64.deb && \
      curl -L -O https://github.com/intel/compute-runtime/releases/download/24.31.30508.7/libigdgmm12_22.4.1_amd64.deb; \
    fi && \
    dpkg -i *.deb && \
    rm -rf /tmp/gpu_deps

ENV LD_LIBRARY_PATH=${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install/lib
ENV OpenCV_DIR=${WORKSPACE}/opencv-4.5.3-openvino-2021.4.2/install/lib/cmake/opencv4

RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
      cython3 \
      git \
      libusb-1.0-0-dev \
      xz-utils \
      "${PYTHON}-dev" \
      "lib${PYTHON}-dev" \
      python-is-python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://bootstrap.pypa.io/get-pip.py | python && \
    python -m pip --no-cache-dir install --upgrade pip setuptools

WORKDIR "${IVSR_OV_DIR}"
RUN git clone ${OV_REPO} ${IVSR_OV_DIR} && \
    git checkout ${OV_BRANCH} && \
    git submodule update --init --recursive

RUN if [ "$ENABLE_OV_PATCH" = "true" ] && [ "$OV_VERSION" = "2022.3" ]; then \
        { set -e; \
          for patch_file in $(find ../patches -iname "*.patch" | sort -n); do \
            echo "Applying: ${patch_file}"; \
            git am --whitespace=fix ${patch_file}; \
          done; }; \
    fi

WORKDIR "${BASED_ON_OPENVINO_DIR}"
RUN mkdir -p "${IVSR_OV_DIR}/build" && \
    cmake \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
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
      -B "${IVSR_OV_DIR}/build" -S "${IVSR_OV_DIR}" && \
    make -j$(nproc) -C ${IVSR_OV_DIR}/build && \
    make -j$(nproc) -C ${IVSR_OV_DIR}/build install && \
    rm -rf "${IVSR_OV_DIR}"

ENV CUSTOM_IE_DIR=${INSTALL_PREFIX}/runtime
ENV OpenVINO_DIR=${CUSTOM_IE_DIR}/cmake
ENV InferenceEngine_DIR=${CUSTOM_IE_DIR}/cmake
ENV TBB_DIR=${CUSTOM_IE_DIR}/3rdparty/tbb/cmake
ENV ngraph_DIR=${CUSTOM_IE_DIR}/cmake
ENV LD_LIBRARY_PATH=${INSTALL_PREFIX}/lib/:${INSTALL_PREFIX}/runtime/lib/intel64/:${INSTALL_PREFIX}/runtime/3rdparty/tbb/lib:$LD_LIBRARY_PATH

WORKDIR "${RAISR_DIR}"
RUN cmake \
      -DENABLE_LOG=OFF \
      -DENABLE_PERF=OFF \
      -DENABLE_THREADPROCESS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
      -B "${IVSR_SDK_DIR}/build" -S "${IVSR_SDK_DIR}" && \
    make -j"$(nproc)" -C "${IVSR_SDK_DIR}/build" && \
    make -j"$(nproc)" -C "${IVSR_SDK_DIR}/build" install

RUN source /opt/intel/common.sh && \
    git_repo_download_strip_unpack "${FFMPEG_REPO}" "refs/tags/${FFMPEG_VERSION}" "${FFMPEG_DIR}" && \
      patch -d "${FFMPEG_DIR}" -p1 < "${IVSR_DIR}/ivsr_ffmpeg_plugin/patches/"*.patch && \
      patch -d "${FFMPEG_DIR}" -p1 < "/opt/intel/ffmpeg/patches/"* && \
    git_repo_download_strip_unpack "${RAISR_REPO}" "${RAISR_BRANCH}" "${RAISR_DIR}" && \
      cp -r "${RAISR_DIR}/filters_2x" "${INSTALL_PREFIX}/filters_2x" && \
      cp -r "${RAISR_DIR}/filters_1.5x" "${INSTALL_PREFIX}/filters_1.5x" && \
    ./build.sh -DENABLE_RAISR_OPENCL=ON \
      -DCMAKE_LIBRARY_PATH="/opt/intel/oneapi/ipp/latest/lib;${PREFIX}/lib;" \
      -DCMAKE_C_FLAGS="-I/opt/intel/oneapi/ipp/latest/include -I/opt/intel/oneapi/ipp/latest/include/ipp" \
      -DCMAKE_CXX_FLAGS="-I/opt/intel/oneapi/ipp/latest/include -I/opt/intel/oneapi/ipp/latest/include/ipp" \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"

#build ffmpeg with iVSR SDK backend and raisr
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libglib2.0-dev \
      gobject-introspection \
      libgirepository1.0-dev \
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
    apt-get clean && \
    rm -rf intel-graphics.key /var/lib/apt/lists/*

WORKDIR "${FFMPEG_DIR}"
RUN if [ -f "${IVSR_OV_DIR}/install/setvars.sh" ]; then \
      . "${IVSR_OV_DIR}/install/setvars.sh" ; \
    fi && \
    ./configure \
      --extra-cflags="-fopenmp -I/opt/intel/oneapi/ipp/latest/include -I/opt/intel/oneapi/ipp/latest/include/ipp -I${INSTALL_PREFIX}/include" \
      --extra-ldflags="-fopenmp -L/opt/intel/oneapi/ipp/latest/lib -L${INSTALL_PREFIX}/lib -L${INSTALL_PREFIX}/runtime/lib/intel64 -L${INSTALL_PREFIX}/runtime/3rdparty/tbb/lib" \
      --disable-shared \
      --disable-debug  \
      --disable-doc    \
      --enable-libivsr \
      --enable-static \
      --enable-vaapi \
      --enable-gpl \
      --enable-libx264 \
      --enable-libx265 \
      --enable-version3 \
      --enable-libipp \
      --enable-opencl \
      --extra-libs='-lraisr -lstdc++ -lippcore -lippvm -lipps -lippi -lm' \
      --enable-cross-compile \
      --prefix="${INSTALL_PREFIX}" && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install

ARG IMAGE_CACHE_REGISTRY
FROM "${IMAGE_CACHE_REGISTRY}/library/ubuntu:22.04@sha256:67cadaff1dca187079fce41360d5a7eb6f7dcd3745e53c79ad5efd8563118240" AS runtime-stage

LABEL org.opencontainers.image.authors="jerry.dong@intel.com,xiaoxia.liang@intel.com,milosz.linkiewicz@intel.com"
LABEL org.opencontainers.image.url="https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite"
LABEL org.opencontainers.image.title="Intel® Media & Entertainment AI Suite"
LABEL org.opencontainers.image.description="Intel® Media & Entertainment AI Suite with OpenCL for RAISR (Rapid and Accurate Image Super Resolution) and iVCR, as FFmpeg plugin. Ubuntu 22.04 Docker image."
LABEL org.opencontainers.image.documentation="https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/blob/main/README.md"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Intel® Corporation"
LABEL org.opencontainers.image.licenses="BSD 3-Clause License"

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/Warsaw"

SHELL ["/bin/bash", "-ex", "-o", "pipefail", "-c"]
WORKDIR /opt/intel_ai_suite
RUN apt-get update --fix-missing && \
    apt-get full-upgrade -y && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      sudo curl unzip tar less \
      gpg \
      libx264-1* \
      libx265-1* \
      libde265-0 \
      libpcre3 \
      zlib1g \
      libglib2.0 \
      libx11-6 \
      libxv1 \
      libxt6 \
      libasound2 \
      libpango1.0-0 \
      libtheora0 \
      libvisual-0.4-0 \
      libgl1-mesa-dri \
      libcurl4 \
      librtmp1 \
      mjpegtools \
      libva2 && \
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
      intel-oneapi-ipp-2022.0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-stage --chown=ivsr:ivsr /install/bin/ffmpeg /usr/local/bin/
COPY --from=build-stage --chown=ivsr:ivsr /install/lib/*so /usr/local/lib
COPY --from=build-stage --chown=ivsr:ivsr /install/runtime/lib/intel64/*so /usr/local/lib
COPY --from=build-stage --chown=ivsr:ivsr /install/runtime/3rdparty/tbb/lib/*so /usr/local/lib
COPY --from=build-stage --chown=ivsr:ivsr /install/workspace/opencv-*-openvino-*/install/lib/*so /usr/local/lib
COPY --from=build-stage --chown=ivsr:ivsr /install/workspace/opencv-*-openvino-*/install/bin/*   /usr/local/bin
COPY --from=build-stage --chown=ivsr:ivsr /install/filters_1.5x /filters_1.5x
COPY --from=build-stage --chown=ivsr:ivsr /install/filters_2x   /filters_2x

ENV LD_LIBRARY_PATH="/opt/intel/oneapi/ipp/latest/lib:/usr/local/lib:/usr/local/lib64:/usr/lib"
RUN ln -s /usr/local/bin/ffmpeg /opt/intel_ai_suite/ffmpeg && \
    ldconfig && \
    echo "------------------===PRE-CHECK-START===------------------" && \
    ldd /usr/local/bin/ffmpeg && \
    echo "------------------===CHECK-START===------------------" && \
    ffmpeg -buildconf && \
    echo "------------------===CHECKS-PASSED===------------------"

USER "ivsr"
SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "/opt/intel_ai_suite/ffmpeg" ]
HEALTHCHECK --interval=30s --timeout=5s CMD ps aux | grep "ffmpeg" || exit 1
