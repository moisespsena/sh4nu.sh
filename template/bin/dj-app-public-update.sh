#!/bin/bash

if [ "$1" = '-h' ]; then
  echo "Usage: $0

Update public path of all apps.
The public directory of app is DJANGO_APP_PATH/public.

Example:
 - DJANGO_APP_PATH/public/static
 - DJANGO_APP_PATH/public/media
"
  exit
fi

D=$(python -c "import os;print(os.path.dirname(os.path.abspath('$0')))") || exit 1
. $(dirname "$D")"/.env" || exit 1

appsd="$SHCP_HOME/python/django-apps"
public_dirs="public"
public_appsd="$SHCP_HOME/www/dj"
dirs="public static"

while read app; do
  [ ! -e "$public_appsd/$app" ] && mkdir -pv "$public_appsd/$app"
  for d in $dirs; do
    lp="$public_appsd/$app/$d"
    [ ! -e "$lp" ] && ln -vs $(python -c "import os;print(os.path.relpath('$appsd/$app/$d','$public_appsd/$app'))") "$lp"
  done
done < <(ls -1 "$appsd")
