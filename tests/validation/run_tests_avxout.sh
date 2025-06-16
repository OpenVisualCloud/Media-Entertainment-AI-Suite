#!/bin/bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 Intel Corporation

set -x

ffmpeg_path="${ffmpeg_path:-/opt/intel_ai_suite}"
test_video_path="${test_video_path:-${ffmpeg_path}/test_videos}"

avx_array=("${1:-avx2}")
if [[ "${avx_array[0]}" == "avx2" ]];
then
  if lscpu | grep "avx512f " | grep "avx512vl ";
  then
    avx_array+=("avx512");
  else
    echo "No avx512 found";
  fi

  if lscpu | grep "avx512_fp16 ";
  then
    avx_array+=("avx512fp16");
  else
    echo "No avx512fp16 found";
  fi
else
  avx_array=("opencl" "gpu")
fi

thread_array=(1 5 10 20 30)
pass_array=(1 2)
blending_array=(1 2)
mode_array=(1 2)
fixed_thread=30

#bad inputs
wrong_bit=9
wrong_blending=0
wrong_ratio=0
wrong_mode=-1
wrong_thread=121
wrong_pass=3
negtive_pass=-1
negtive_thread=-1
bad_configs=(12_3_3_11 24_3_3 24_3_3_6 24_3_3_9)
bad_nums=(bad_cohpath_nums bad_hashtable_nums bad_strpath_nums)
no_pathes=(noCohPath noConfig noHashTable noStrPath)
#log path
common_log_path="${ffmpeg_path}/test_logs"
wrong_input_log_path="${ffmpeg_path}/test_bad_input_logs"
opath="${ffmpeg_path}/outputs/"
mkdir -p "${common_log_path}" "${wrong_input_log_path}" "${opath}"

cd "$ffmpeg_path" || exit 10
for filename in "$test_video_path/"*; do
    fname=$(basename "$filename")
    ext="${fname##*.}"
    fname1="${fname%.*}"
    ofname="$fname1"_out."$ext"
    if [[ "$fname1" == *"10bit"* ]]; then
      profile=high10
    else
      profile=high
    fi
    for avx in "${avx_array[@]}"; do
      PREFIX=('-y' '-i' "${filename}")
      PLUGIN="raisr=threadcount=${fixed_thread}:asm=${avx}:"
      SUFIX=""
      PAST_SUFIX=()

      if [[ "${avx}" == "gpu" ]]; then
        PREFIX=('-init_hw_device' 'vaapi=hw:/dev/dri/renderD128' '-init_hw_device' 'opencl=ocl@va' '-hwaccel' 'vaapi' '-hwaccel_output_format' 'vaapi' '-v' 'verbose' '-y' '-i' "${filename}")
        PLUGIN="hwmap=derive_device=opencl,format=opencl,raisr_opencl="
        SUFIX=",hwmap=derive_device=vaapi:reverse=1:extra_hw_frames=16"
        PAST_SUFIX=("-c:v" "hevc_vaapi")
      fi

      if [[ "${avx}" != "gpu" ]]; then
      #test diff thread &diff avx
        for thread in "${thread_array[@]}"; do
	      printf -v digi '%02d' ${thread##+(0)}
          ofname="$fname1"_out_th"$digi"_"$avx".mp4
          ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${thread}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${common_log_path}/test_log_$ofname.log" 2>&1
        done
      #bad mode
        printf -v digi '%02d' ${wrong_mode##+(0)}
        ofname="$fname1"_out_wmod"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${fixed_thread}:mode=${wrong_mode}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${wrong_input_log_path}/test_log_$ofname.log" 2>&1
      #bad thread count
        printf -v digi '%02d' ${wrong_thread##+(0)}
        ofname="$fname1"_out_wth"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${wrong_thread}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${wrong_input_log_path}/test_log_$ofname.log" 2>&1
      #negtive thread
        printf -v digi '%02d' ${negtive_thread##+(0)}
        ofname="$fname1"_out_nth"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${negtive_thread}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${wrong_input_log_path}/test_log_$ofname.log" 2>&1
      #directory_input
        ofname="$fname1"_directory_input_"$avx".mp4
        ./ffmpeg -y -i $test_video_path -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${fixed_thread}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${wrong_input_log_path}/test_log_$ofname.log" 2>&1
      #no_input #Did you mean file:-profile:v?
        ofname="$fname1"_no_input_"$avx".mp4
        ./ffmpeg -y -i -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "raisr=threadcount=${fixed_thread}:asm=${avx}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"${wrong_input_log_path}/test_log_$ofname.log" 2>&1
      fi

    #test diff pass &diff avx, thread is fixed to 120
        for pass in "${pass_array[@]}"; do
	    printf -v digip '%02d' ${pass##+(0)}
            ofname="$fname1"_out_pass"$digip"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}passes=${pass}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        done

    #test diff blending &diff avx, thread is fixed to 120
        for blending in "${blending_array[@]}"; do
        printf -v digib '%02d' "${blending##+(0)}"
            ofname="$fname1"_out_bld"$digib"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}blending=${blending}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        done

    #test diff mode &diff avx, thread is fixed to 120
        for mode in "${mode_array[@]}"; do
        printf -v digim '%02d' "${mode##+(0)}"
            ofname="$fname1"_out_mode"$digim"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}mode=${mode}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        done

    #test diff filter_1 &diff avx, thread is fixed to 120
        for f in /filters_1*/*; do
            digif="${f/"/"/"_"}"
            ofname="$fname1"_out_ft"$digif"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}filterfolder=${f}:ratio=1.5${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        done

    #test diff filter_2 &diff avx, thread is fixed to 120
        for f in /filters_2*/*; do
            digif="${f/"/"/"_"}"
            ofname="$fname1"_out_ft"$digif"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}filterfolder=${f}:ratio=2.0${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        done

    #test diff bit &diff avx, thread is fixed to 120
        result=$(echo "${fname1}" | grep "10bit")
        if [[ "$result" != "" ]]
        then
            ofname="${fname1}_out_bit10_${avx}.mp4"
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}bits=10${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        else
            ofname="${fname1}_out_bit08_${avx}.mp4"
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}bits=8${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$common_log_path/test_log_$ofname.log" 2>&1
        fi

    #test wrong inputs
        #bad bits:
        printf -v digi '%02d' ${wrong_bit##+(0)}
        ofname="$fname1"_out_wbit"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}bits=${wrong_bit}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #bad blending:
        printf -v digi '%02d' ${wrong_blending##+(0)}
        ofname="$fname1"_out_wbld"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}blending=${wrong_blending}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #bad raito
        printf -v digi '%02d' ${wrong_ratio##+(0)}
        ofname="$fname1"_out_wrat"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}radio=${wrong_ratio}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #bad pass
        printf -v digi '%02d' ${wrong_pass##+(0)}
        ofname="$fname1"_out_wps"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}passes=${wrong_pass}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #not matching pass&mode#[RAISR WARNING] 1 pass with upscale in 2d pass, mode = 2 ignored !
        ofname="$fname1"_no_match_pm_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}passes=1:mode=2${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #negtive pass
        printf -v digi '%02d' ${negtive_pass##+(0)}
        ofname="$fname1"_out_nps"$digi"_"$avx".mp4
        ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}passes=${negtive_pass}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        #bad config 12 3 3 11|24 3 3|24 3 3 6|24 3 3 9
        for config in "${bad_configs[@]}"; do
            ofname="$fname1"_config_"$config"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}filterfolder=filters_wrongConfig/filters1_${config}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        done
        #bad nums
        for badpath in "${bad_nums[@]}"; do
            ofname="$fname1"_"$badpath"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}filterfolder=filters_badNums/filters1_${badpath}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        done
        #no pathes
        for confpath in "${no_pathes[@]}"; do
            ofname="$fname1"_"$confpath"_"$avx".mp4
            ./ffmpeg "${PREFIX[@]}" -profile:v "${profile}" -b:v 6M -maxrate 12M -bufsize 24M -crf 28 -vf "${PLUGIN}filterfolder=filters_noPathes/filters1_${confpath}${SUFIX}" "${PAST_SUFIX[@]}" "${opath}${ofname}" >"$wrong_input_log_path/test_log_$ofname.log" 2>&1
        done
    done
done
set +x

error=0
test_logs_error=0
test_bad_input_error=0

echo "========== Start of summary"
echo "Finished tests:"
echo "Test logs: ${ffmpeg_path}/test_logs"
echo "Test bad input logs: ${ffmpeg_path}/test_bad_input_logs"
echo "Test outputs: ${ffmpeg_path}/outputs/"
echo "Results: (print errors only)"
echo "Should find 0 match per file: grep -c failed ${ffmpeg_path}/test_logs/*"

for file in "${ffmpeg_path}/test_logs/"*; do
  grep -Ec "Error|failed|not found|Is a directory" "${file}" > /dev/null
  ret=$?
  if [[ "$ret" == "0" ]]; then
    echo "Error in: ${file}"
    test_logs_error=1
    error=1
  fi
done

if [[ "$test_logs_error" == 0 ]]; then
  echo "SUCCESS - no errors found"
fi

echo "Should find 1 or more match per file:"
echo "grep -Ec \"Error|failed|not found|RAISR WARNING|Is a directory\" ${ffmpeg_path}/test_bad_input_logs/*"

for file in "${ffmpeg_path}/test_bad_input_logs/"*; do
  grep -Ec "Error|failed|not found|RAISR WARNING|Is a directory" "${file}" > /dev/null
  ret=$?
  if [[ "$ret" == "1" ]]; then
    echo "Error in: ${file}"
    test_bad_input_error=1
    error=1
  fi
done

if [[ "$test_bad_input_error" == "0" ]]; then
  echo "SUCCESS - no errors found"
fi
echo "========== End of summary"

echo "Errors in test_logs: ${test_logs_error}"
echo "Errors in test_bad_input: ${test_bad_input_error}"
echo "Summary job resulting in exit code: ${error}"

DIRDATE="/opt/intel_ai_suite/test_videos/.logs-comopsed-output/$(date +%s__%H:%M_%d-%m-%Y)/"
mkdir -p "${DIRDATE}"
cat "${ffmpeg_path}/test_bad_input_logs/"* "${ffmpeg_path}/test_logs/"* > "${DIRDATE}/composed-oputput.log"

exit "${error}"
