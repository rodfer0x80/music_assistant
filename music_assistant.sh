#!/bin/bash
# ----
# AUTHOR
# rodfer0x80
# https://rodfer.cloud/
# https://github.com/rodfer0x80
# ----
# LICENSE
# ----
# GLP 2.0
# ----
# DEPENDENCIES
# ffmpeg
# mpd
# mpc
# sox
# --


# models :: 0 -> small || >0 -> full 
MODEL=0
# --
VOSK_MODEL_PATH="/home/rodfer/.cache/music_assistant/models"
MUSIC_SOURCE="https://www.youtube.com"
# --

PYREQ="\
    vosk \
    yt-dlp \
    google-speech \
    "

CWD="$PWD"
SRC="$(dirname $0)"

cd ~/.cache || exit 1
test -e ./music_assistant || mkdir ./music_assistant || exit 2
cd ./music_assistant

if ! [ -e ./models ]; then
    if [ $MODEL -eq 0 ]; then
        URL=$(curl -s https://alphacephei.com/vosk/models | grep -oE 'https://alphacephei.com/vosk/models/[a-zA-Z0-9./?=_-]+' | grep -i small | head -n 1)
    else 
        URL=$(curl -s https://alphacephei.com/vosk/models | grep -oE 'https://alphacephei.com/vosk/models/[a-zA-Z0-9./?=_-]+' | grep -i en | head -n 2 | tail -n 1)
    fi
    FILE=$(echo $URL | cut -d'/' -f6)
    wget $URL
    unzip $FILE
    mv $(echo $FILE | cut -d'.' -f1) ./models
fi

cd ~/.cache/music_assistant
test -e "./venv" ||\
    python3 -m venv "./venv" &&\
    source "./venv/bin/activate" &&\
    python3 -m pip install --upgrade pip &&\
    echo $PYREQ | xargs python3 -m pip install || exit 4
source "./venv/bin/activate"

mpc stop
mpc clear

WAV_FILE=$(mktemp --suffix=.wav)
TXT_FILE=$(mktemp --suffix=.txt)
rm "$WAV_FILE" "$TXT_FILE"

ffmpeg -y -f alsa -i default -acodec pcm_s16le -ac 1 -ar 44100 -t 4 -f wav "$WAV_FILE"
vosk-transcriber -m $VOSK_MODEL_PATH -i "$WAV_FILE" -o "$TXT_FILE"
read AUDIO_INPUT < "$TXT_FILE"

google_speech "Found ...  $AUDIO_INPUT" &

QUERY="$(printf '%s' "song audio $AUDIO_INPUT" | tr ' ' '+' )"
VIDEO_ID="$(curl -s "$MUSIC_SOURCE/results?search_query=$QUERY" | grep -oh "/watch?v[^\"*]\+" | head -n 1)"
YOUTUBE_URL=$(echo "https://youtube.com$VIDEO_ID" | cut -d "\\" -f1)
AUDIO_URL="$(yt-dlp -f bestaudio --get-url "$YOUTUBE_URL")"

sleep 1
mpc add "$AUDIO_URL"
sleep 2 # needed to load, can adjust for setup
mpc play
sleep 1
