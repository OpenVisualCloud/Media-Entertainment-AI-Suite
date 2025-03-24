docker build --build-arg http_proxy=$http_proxy \
  --build-arg https_proxy=$https_proxy \
  --build-arg no_proxy=$no_proxy \
  --build-arg PYTHON=python3.10 \
  --build-arg ENABLE_OV_PATCH=false \
  --build-arg OV_VERSION=2024.5 \
  -f Dockerfile -t ivsr_raisr \
  ../

# load ivsr_raisr:latest image into crictl
docker save -o ivsr_raisr.tar ivsr_raisr:latest
sudo ctr -n k8s.io images import ivsr_raisr.tar
rm ivsr_raisr.tar

