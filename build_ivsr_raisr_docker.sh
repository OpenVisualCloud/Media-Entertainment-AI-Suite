#!/bin/bash

docker_tag="docker.io/ivsr_raisr:25.04-alpha"

docker build --build-arg http_proxy="${http_proxy:-}" \
  --build-arg https_proxy="${https_proxy:-}" \
  --build-arg no_proxy="${no_proxy:-}" \
  --build-arg PYTHON=python3.10 \
  --build-arg ENABLE_OV_PATCH=false \
  --build-arg OV_VERSION=2024.5 \
  -f Dockerfile -t "${docker_tag}" \
  ./

# load ${docker_tag} image into crictl
docker save -o ivsr_raisr.tar "${docker_tag}"
sudo ctr -n k8s.io images import ivsr_raisr.tar
rm ivsr_raisr.tar
