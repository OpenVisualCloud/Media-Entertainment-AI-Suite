#!/bin/bash

docker_tag="docker.io/ivsr_raisr:25.04-alpha"

function build_docker_image()
{
  docker build --build-arg http_proxy="${http_proxy:-}" \
    --build-arg https_proxy="${https_proxy:-}" \
    --build-arg no_proxy="${no_proxy:-}" \
    --build-arg PYTHON=python3.10 \
    --build-arg ENABLE_OV_PATCH=false \
    --build-arg OV_VERSION=2024.5 \
    -f Dockerfile -t "${docker_tag}" \
    --target runtime-stage --progress=plain \
    ./
}

function export_to_ctr()
{
  # load ${docker_tag} image into crictl
  docker save -o ivsr_raisr.tar "${docker_tag}"
  sudo ctr -n k8s.io images import ivsr_raisr.tar
  rm ivsr_raisr.tar
}

build_docker_image || exit 1
[[ "${EXPORT_TO_CTR}" == "1" ]] && export_to_ctr

