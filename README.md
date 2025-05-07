# Media & Entertainment AI Suite

[![Linter](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/linter.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/linter.yml)
[![Anti Virus Scan](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/anti_virus_scan.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/anti_virus_scan.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/badge)](https://securityscorecards.dev/viewer/?uri=github.com/OpenVisualCloud/Media-Entertainment-AI-Suite)
[![Docker Build](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/build_docker.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/build_docker.yml)
[![Trivy](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/trivy.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/trivy.yml)
> [!TIP]
> [Full Documentation](https://openvisualcloud.github.io/Media-Entertainment-AI-Suite) for [Intel®](https://intel.com) [Media & Entertainment AI Suite](https://openvisualcloud.github.io/Media-Entertainment-AI-Suite).

The main goal of developing AI Suites is to facilitate customer evaluation. The current Media Entertainment AI Suite include video super-resolution and smart video preprocessing. For video super-resolution, both iVSR and RAISR envoriment are supported. Users can choose models IVSR supported or RAISR to do video super-resolution.

## Installing

### Prerequisites
- Linux based OS
- [Docker](https://www.docker.com/)
- [Kubernetes](https://kubernetes.io/docs/home/)
- [Hlem Charts](https://helm.sh/)
- Option: Intel GPU devices require [Intel GPU device plugin for Kubernetes](https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html)

### Building iVSR RAISR Image

Just run the below command to build ivsr_raisr image

```bash
./build_ivsr_raisr_docker.sh
```

This will result in docker image named `ivsr_raisr:latest` with both `ivsr v24.12` and `raisr v23.11.1` included.

### [Option] Instructions to Deploy AI Suite on Intel GPU

To deploy the AI Suite on an Intel GPU, you need to set up the Intel GPU device plugin and modify the Helm chart's deployment.yaml file to require GPU resources.

#### Deploy Intel GPU Device Plugin

To begin, deploy the Intel GPU device plugin for Kubernetes by following the instructions [Intel GPU device plugin for Kubernetes](https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html#install-with-nfd).

#### Update Helm Chart for AI Suite Deployment

Modify the helm/templates/deployment.yaml file of the AI Suite to request the necessary GPU resources. This involves uncommenting and editing the relevant YAML configuration block as follows:

```yaml
          # Uncomment these for GPU resources requirement
          resources:
            limits:
              gpu.intel.com/i915: 1
            requests:
              gpu.intel.com/i915: 1
```
Ensure the above configuration is placed correctly under the container specification where GPU resources are needed.
With these changes, the AI Suite should be configured to utilize an Intel GPU on your Kubernetes cluster

### Installing Helm Charts to Start a AI Suite Service

To install the Helm Charts to start AI Suite service to process videos via ffmpeg command with ivsr or raisr filter, use the Helm charts located in the [/helm](helm) directory.
Before proceeding with the installation, ensure that you provide the necessary values for specific parameters in the `values.yaml` file.
Below is an example of the settings in `values.yaml`. For detailed information on using ivsr and raisr parameters, please refer to their documentation.

```yaml
# Set directory path of test video and output both on host directory that application will process all videos in mp4 format in test_video_dir directory
# and save the output with mp4 format in the output_dir directory
test_video_dir: /home/spr-lxx/workspace/aime_cemp_mwc/demo_video/bbb/input/
output_dir: /home/spr-lxx/workspace/output/
# Set directory path which include IR file (.xml and .bin)
model_dir: /home/spr-lxx/workspace/ivsr/ivsr_2024.05/SVP_Basic/dunet_2024.01/INT8-performance/

# Filter Configuration
# One service only support select one filter from ivsr and raisr to process videos.
# Select either ivsr or raisr for video processing by setting the 'selected' property to true.
# Such as set `selected` of ivsr item to true and `selected` of raisr to false to select ivsr filter to do process videos.
# Refer to the documentation of ivsr and raisr for configuration details.
filter_parameters:
  ivsr:
    selected: true
    configuration:
      format: rgb24
      model_name: dunet.xml
      nif: 1
      model_type: 1
      normalize_factor: 1.0
      device: CPU

  raisr:
    selected: false
    configuration:
      threadcount: 20
      ratio: 2
      bits: 8
      passes: 1
      asm: avx512
      filterfolder: filters_2x/filters_highres

# Specify codec parameter, current supports libx264 and libx265 encoders
codec_parameters:
  encoder: libx264
  bitrate: 5M
  profile: main
  pix_fmt: yuv420p
```

User can install the Chart using the following command after configuring the `values.yaml` file:

```bash
helm install ai-suite ./helm
```

Subsequently, the Helm chart named `ai-suite` was deployed, and the `ai-suite-server-xxx` pod was created that list pods via `kubectl get pods`.
This pod empolys ffmpeg to process videos located within the `test_video_dir`, generates outputs in the `output_dir`. The status of `ai-suite-server-xxx` pod shows "Running", which means the service is processing the videos with specified filter via ffmpeg command.

### Check Output Videos and Uninstall Helm Charts to Terminate the Service

Users can determine whether the service is completed by checking the status of the `ai-suite-server-xxx` pod. If the status is completed, it means that the service is completed and all videos have been processed.
And then can check output videos in the `output_dir` directory on host, the output files are named ivsr_output_xxx.mp4 or raisr_output_xxx.mp4.

It needs to terminate the ai-suite service via uninstalling Helm Charts after the serive is completed.

```bash
helm uninstall ai-suite
```

## Note

This project is under development.
All source code and features on the main branch are for the purpose of testing or evaluation and not production ready.
