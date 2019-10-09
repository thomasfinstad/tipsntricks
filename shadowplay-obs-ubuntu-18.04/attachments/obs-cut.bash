obs-cut-usage() {
    echo "Usage: obs-cut [-i <input file>] [-f <start time in seconds or HH:MM:SS>] [-t <end time in seconds or HH:MM:SS>] [-a \"<audio tracks, space seperated, default is desktop>\"]" 1>&2
    echo -e "$1" 1>&2
    return 1
}
obs-cut(){ # [-h] Cut and pick audio of obs replaybuffer generated files.
    local OPTIND o i f t a timestamps enabled_tracks enabled_tracks_num enabled_tracks_name timestamp_regex output_folder tracks

    tracks=(\
        "full"\
        "game"\
        "com"\
        "mic"\
        "desktop"\
        "null"\
    )

    timestamp_regex="^[0-9:]*$"

    output_folder="./cut"

    ## Script



    enabled_tracks_num=0

    while getopts ":i:f:t:a:" o; do
        case "${o}" in
            i)
                i=${OPTARG}
                [[ -f "${i}" ]] || obs-cut-usage "Could not find input file '${i}'" || return 1
                echo "File: ${i}"
            ;;
            f)
                f=${OPTARG}
                [[ $f =~ $timestamp_regex ]] || obs-cut-usage "Start time did not match regex $timestamp_regex" || return 1
                timestamps="-ss ${f}"
            ;;
            t)
                t=${OPTARG}
                [[ $t =~ $timestamp_regex ]] || obs-cut-usage "End time did not match regex $timestamp_regex" || return 1
                timestamps+=" -to ${t}"
            ;;
            a)
                for track in ${OPTARG}; do
                    found=false
                    for track_num in ${!tracks[@]}; do
                        #echo "InputTrack:$track Element:$track_num Name:${tracks[$track_num]}"
                        if [ "${tracks[$track_num]}" == "$track" ]; then
                            found=true
                            echo "Enabling audio track: $track [0:a:$track_num]"
                            enabled_tracks+="[0:a:$track_num]"
                            enabled_tracks_num=$((++enabled_tracks_num))
                            enabled_tracks_name+="_${tracks[$track_num]}"
                        fi
                    done
                    #echo "Enabled audio tracks: $enabled_tracks"
                    if ! $found; then
                        obs-cut-usage "Audio track not found, valid tracks are '${tracks[*]}'" || return 1
                    fi
                done
            ;;
            *)
                obs-cut-usage "Wrong or missing parameter\nValid audio tracks are '${tracks[*]}'" || return 1
            ;;
        esac
    done
    shift "$((OPTIND-1))"

    if [ "x${i}" == "x" ]; then
        obs-cut-usage "Input file must be specified. Got '${i}'" || return 1
    fi

    if [ "$enabled_tracks_num" -eq 0 ]; then
        echo "No audio track selected, trying to enable desktop track"
        track="desktop"
        for track_num in ${!tracks[@]}; do
            #echo "InputTrack:$track Element:$track_num Name:${tracks[$track_num]}"
            if [ "${tracks[$track_num]}" == "$track" ]; then
                found=true
                echo "Enabling audio track: $track [0:a:$track_num]"
                enabled_tracks+="[0:a:$track_num]"
                enabled_tracks_num=$((++enabled_tracks_num))
                enabled_tracks_name+="_${tracks[$track_num]}"
            fi
        done
    fi

    mkdir -p "${output_folder}"
    output="$( echo "${output_folder}/${i}${enabled_tracks_name}.mp4" | tr " " "_" )"

    ffmpeg_command="ffmpeg -i '${i}' \
        ${timestamps} \
        -filter_complex '${enabled_tracks}amerge=inputs=${enabled_tracks_num}[a]' \
        -map '0:v:0' \
        -c:v libx264 \
        -preset veryfast \
        -crf 18 -bf 2 \
        -map '[a]' \
        -c:a aac \
        -q:a 1 \
        -ac 2 \
        -ar 48000 \
        -movflags +faststart \
        '${output}'"

    echo "$ffmpeg_command"
    eval "$ffmpeg_command"

    echo "Done: file://$(realpath "${output}")"
}
