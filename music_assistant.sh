#!/bin/bash


# setup py venv
test -e "$PWD/venv" ||\
    python3 -m venv "$PWD/venv" &&\
    source "$PWD/venv/bin/activate" &&\
    pip install --upgrade pip &&\
    pip install -r "$PWD/requirements.txt"

source "$PWD/venv/bin/activate"
# clear mpc
mpc stop
mpc clear

VOSK_MODEL_PATH="$PWD/models" # vosk models path
MUSIC_SOURCE="https://www.youtube.com"

# audio input
ffmpeg -y -f alsa -i default -acodec pcm_s16le -ac 1 -ar 44100 -t 4 -f wav /tmp/mic_audio.wav

# speech to text
vosk-transcriber -m $VOSK_MODEL_PATH -i /tmp/mic_audio.wav -o /tmp/mic_audio.txt
read audio_input < /tmp/mic_audio.txt

# text to speech
google_speech "Now playing ...  $audio_input" &

# get mpc uri
query="$(printf '%s' "song audio $audio_input" | tr ' ' '+' )"
video_id="$(curl -s "$MUSIC_SOURCE/results?search_query=$query" | grep -oh "/watch?v[^\"*]\+" | head -n 1)"
youtube_url=$(echo "https://youtube.com$video_id" | cut -d "\\" -f1)
audio_url="$(yt-dlp -f bestaudio --get-url "$youtube_url")"

# exit py venv
deactivate

# play sound
sleep 2
mpc add "$audio_url"
sleep 4 # needed to load, can adjust for setup
mpc play
sleep 4
