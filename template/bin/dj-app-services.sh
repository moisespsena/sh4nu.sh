#!/bin/bash

D=$(python -c "import os;print(os.path.dirname(os.path.abspath('$0')))") || exit 1
. $(dirname "$D")"/.env" || exit 1

load_env django_utils

dj_load "$1"
dj_info
echo


cd "$dj_app_path/$DJANGO_APP" || exit 1

sfx=$$

[  "$DJ_NAME" != '' ] && sfx="$DJ_NAME"

pidf="/run/$USER/snhm/dj-$dj_app-services-$sfx.pid"
main_pidf="/run/$USER/snhm/dj-$dj_app-services-$sfx-main.pid"

on_done rm -vf "$pidf"

shcp_exec bin/services.sh
