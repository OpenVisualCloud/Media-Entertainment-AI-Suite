#!/bin/bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 Intel Corporation

REPO_DIR="$(readlink -f "/opt/intel_ai_suite")"

ffmpeg_path="${ffmpeg_path:-${REPO_DIR}/}"
out_filters=(filters_badNums  filters_wrongConfig filters_noPathes)
bad_configs=(12_3_3_11 24_3_3 24_3_3_6 24_3_3_9)
bad_nums=(bad_cohpath_nums bad_hashtable_nums bad_strpath_nums)
no_pathes=(noCohPath noConfig noHashTable noStrPath)

for outfilter in "${out_filters[@]}"; do
    echo $outfilter
    if [ -e $outfilter ]
    then
        rm -rf $outfilter
    fi
    mkdir -p "$ffmpeg_path/$outfilter"
    case "$outfilter" in
        "filters_badNums")
            for bad_num in "${bad_nums[@]}"; do
                mild_path=filters1_$bad_num
                cp -r /filters_2x/filters_highres "$ffmpeg_path/$outfilter/$mild_path"
                cd "$ffmpeg_path/$outfilter/$mild_path" || exit 10
                case "$mild_path" in
                    "filters1_bad_cohpath_nums")
                        mv Qfactor_cohbin_2_8 Qfactor_cohbin_6_8
                        mv Qfactor_cohbin_2_8_2 Qfactor_cohbin_6_8_2
                        mv Qfactor_cohbin_2_10 Qfactor_cohbin_6_10
                    ;;
                    "filters1_bad_hashtable_nums")
                        mv filterbin_2_8 filterbin_6_8
                        mv filterbin_2_8_2 filterbin_6_8_2
                        mv filterbin_2_10 filterbin_6_10
                    ;;
                    "filters1_bad_strpath_nums")
                        mv Qfactor_strbin_2_8 Qfactor_strbin_6_8
                        mv Qfactor_strbin_2_8_2 Qfactor_strbin_6_8_2
                        mv Qfactor_strbin_2_10 Qfactor_strbin_6_10
                    ;;
                esac
                cd "$OLDPWD" || exit 10
            done
        ;;
        "filters_wrongConfig")
            for bad_conf in "${bad_configs[@]}"; do
                mild_path=filters1_$bad_conf
                cp -r /filters_2x/filters_highres "$ffmpeg_path/$outfilter/$mild_path"
                cd "$ffmpeg_path/$outfilter/$mild_path" || exit 10
                confignum=${bad_conf//_/ }
                sed -i "1c$confignum" config
                cd "$OLDPWD" || exit 10
            done
        ;;
        "filters_noPathes")
            for bad_path in "${no_pathes[@]}"; do
                mild_path=filters1_$bad_path
                cp -r /filters_2x/filters_highres "$ffmpeg_path/$outfilter/$mild_path"
                cd "$ffmpeg_path/$outfilter/$mild_path" || exit 10
                echo $mild_path
                type_Coh=$(echo $mild_path | grep "Coh")
                type_Conf=$(echo $mild_path | grep "Conf")
                type_Hash=$(echo $mild_path | grep "Hash")
                if [[ "$type_Coh" != "" ]]
                then
                    rm -rf Qfactor_cohbin_*
                elif [[ "$type_Conf" != "" ]]
                then
                    rm -rf config
                elif [[ "$type_Hash" != "" ]]
                then
                    rm -rf filterbin*
                else
                    rm -rf Qfactor_strbin_*
                fi
                cd "$OLDPWD" || exit 10
            done
        ;;
    esac
done
