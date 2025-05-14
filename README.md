# Media & Entertainment AI Suite

[![Linter](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/linter.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/linter.yml)
[![Anti Virus Scan](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/anti_virus_scan.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/anti_virus_scan.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/badge)](https://securityscorecards.dev/viewer/?uri=github.com/OpenVisualCloud/Media-Entertainment-AI-Suite)
[![Docker Build](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/build_docker.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/build_docker.yml)
[![Trivy](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/trivy.yml/badge.svg)](https://github.com/OpenVisualCloud/Media-Entertainment-AI-Suite/actions/workflows/trivy.yml)
> [!TIP]
> [Full Documentation](https://openvisualcloud.github.io/Media-Entertainment-AI-Suite) for [Intel®](https://intel.com) [Media & Entertainment AI Suite](https://openvisualcloud.github.io/Media-Entertainment-AI-Suite).

## Introduction
The Media and Entertainment AI Suite is a cloud-native suite of docker containers, reference pipelines, libraries and pre-trained models that are designed to enhance video quality, improve user experience and lower costs for video service providers, such as broadcasters, video streamers, and social media service providers.
These suites leverage Intel's AI libraries and frameworks, such as the Enterprise AI Framework and OpenVINO™, to deliver high-value media enhancement use cases.
Key workloads supported include:
- Video Super Resolution (VSR): Supports real-time or batch up-scaling of content from older pre-HD formats to HD and 4K, including support for 8-bit and 10-bit content. VSR is available through a range of different up-scaling models, providing a trade-off between video quality and run-time performance.
- Video Bit Rate Optimization (SVP): Reduces video bit rate without compromising video quality, and is compatible with standard CODECs such as AVC, HEVC and AV1. Helps to reduce costs through lower transmission and storage requirements.

The libraries included in the suite are supported on both Intel® Xeon™ CPUs and Intel® Data Center GPUs, and can be easily integrated into existing workflows using FFmpeg plugins provided as part of the libraries.
The libraries are also available as part of the [Intel® Edge AI Suites](https://github.com/open-edge-platform/edge-ai-suites) platform, the [Intel® Tiber™ Broadcast Suite](https://github.com/OpenVisualCloud/Intel-Tiber-Broadcast-Suite), and the [Open Visual Cloud project](https://github.com/OpenVisualCloud/Intel-Tiber-Broadcast-Suite).

### Key Features
- **Video Super Resolution:** Includes support for four pre-trained models, optimized for best performance on Intel® Xeon™ CPUs and Intel® Datacenter GPU hardware.
  - **Enhanced RAISR** – Optimized C/C++ implementation of the [Rapid and Accurate Image Super Resolution (RAISR)](https://arxiv.org/abs/1606.01299) [(PDF)](https://arxiv.org/pdf/1606.01299.pdf) algorithm, with pre-trained filters to support 1.5 and 2x up-scaling, with options for low-res, high-res, and denoising.
  Details of this algorithm can be found in our joint paper with AWS presented at [Mile High Video 2024](https://dl.acm.org/doi/10.1145/3638036.3640290).
  - **TSENet** (Temporally Stabilized ETDS Network) – Optimized implementation of the [ETDS](https://github.com/ECNUSR/ETDS) algorithm for 2x up-scaling, with enhancements for multi-frame temporal stabilization.\
  Details of this algorithm can be found in our papers presented at Mile High Video 2025, and at the [NAB 2025 BEIT](https://nabpilot.org/product/tsenet-video-super-resolution-for-broadcast-television/) conference.
  - **Enhanced EDSR** – Optimized implementation of the [EDSR](https://arxiv.org/pdf/1707.02921) [(PDF)](https://arxiv.org/pdf/1707.02921.pdf) algorithm for 2x up-scaling, using OpenVINO.
  - **Enhanced BasicVSR** – Optimized implementation of the [BasicVSR](https://arxiv.org/abs/2012.02181) [(PDF)](https://arxiv.org/pdf/2012.02181.pdf) algorithm for 2x up-scaling, using OpenVINO.
- **Video Bit Rate Optimization** (Smart Video Processing aka "**SVP**"): This pre-processor works with any standard codec (HEVC, AVC, and AV1) to reduce the video bit-rate of the encoder output without impacting video quality (as measured by VMAF metrics).
- **Hardware Platforms Supported** – All VSR and SVP models are optimized for Intel® Xeon™ CPUs and Intel® Datacenter GPUs, and take advantage of support for real-time processing and acceleration through Intel® Advanced Vector Extensions (Intel® AVX) and Intel® Advanced Matrix Extensions (Intel® AMX).

  | Algorithm | Processor Families<sup>[1] | CPU Instruction Sets | Intel GPU Support |
  |-----------|--------------------|----------------------|-------------------|
  | Enhanced RAISR | 3rd Gen Intel® Xeon™ Scalable (Ice Lake)<br>4th Gen Intel Xeon Scalable (recommended) and later | Intel® AVX (AVX2, AVX512, and AVX512FP16) | Flex 170 |
  | TSENet | 4th Gen Intel Xeon Scalable and later |Intel® AMX (FP16) | Flex 170<br>ARC770 |
  | Enhanced EDSR |4th Gen Intel® Xeon™ Scalable and later |Intel® AMX (FP32 and INT8) | Flex 170<br>ARC770 |
  | Enhanced Basic VSR| 4th Gen Intel Xeon Scalable and later | Intel AMX (FP32) | Flex 170<br>ARC770 |
  | SVP | 4th Gen Intel Xeon Scalable and later | Intel AMX (FP16 and INT8) | Flex 170<br>ARC770 |

  [1]: In general, the VSR and SVP models will run on other Intel processors that support the instruction set extensions listed. However, caveat emptor applies, as the models, pipelines and plugins have not been specifically tested or validated on processors except those listed here.

- Supported Video Formats – All VSR and SVP models support output formats up to 4K, including support for 8 and 10 bit data.

  | Algorithm | Output Resolutions | Output Formats |
  |-----------|--------------------|----------------|
  | Enhanced RAISR | All resolutions up to 4K<br>1.5x and 2.0x up-scaling supported | 8-bit<br>10-bit (4:2:0, 4:2:2, and 4:4:4) |
  | TSENet | All resolutions up to 4K	| 8-bit |
  | Enhanced EDSR	| All resolutions up to 4K | 8-bit<br>10=bit (pre-release) |
  | SVP	| All resolutions up to 4K | 8-bit<br>10-bit |

- **FFmpeg Plug-in API** – All VSR and SVP models are supported by plug-ins that integrate the algorithms as FFmpeg filters.
  - **Enhanced RAISR** is supported by its own plugin, which is located in the [Intel® Library for Super Resolution](https://github.com/OpenVisualCloud/Video-Super-Resolution-Library) repository.
  - The **iVSR** plugin is provided in the [iVSR](https://github.com/OpenVisualCloud/iVSR) project repository, and supports all other VSR models and SVP. The iVSR API can also be used to integrate custom DL-based VSR and preprocessor models into FFmpeg.

### Value Proposition for End Users:
- Broadcasters: Lower cost production of 4K broadcasts by using HD cameras, sources, and networking, with real-time up-scaling to 4K as the final step before the broadcast/streaming feed.
- Video Streaming Providers: Monetization of older and lower quality content by converting to modern HD and 4K formats.
- Social Media Providers: Improved user experience and satisfaction from higher resolution content.
- Cloud Service Providers: Faster deployment through pre-trained AI models and pre-configured containers, integrating seamlessly with cloud and edge infrastructure for flexible deployment.


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

This will result in docker image named `docker.io/ivsr_raisr:25.04-alpha` with both `ivsr v25.03` and `raisr v23.11.1` included.

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
