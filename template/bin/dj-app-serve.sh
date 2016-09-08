#!/bin/bash

D=$(python -c "import os;print(os.path.dirname(os.path.abspath('$0')))") || exit 1
. $(dirname "$D")"/.env" || exit 1

load_env django_utils

dj_load "$1"
dj_info
dj_gun_info

gexe=$(which gunicorn) || {
  echo Gunicorn command does not exists.
  exit 1
}

dj_gun_exec
