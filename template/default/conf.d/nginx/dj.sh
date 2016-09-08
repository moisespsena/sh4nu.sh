main() {
  local base_path=$(dirname "$BASH_SOURCE")

(ls -1 "$SHCP_HOME/python/django-apps" 2>/dev/null) | while read app; do
  app=$(basename "$app")
  appconf="$SHCP_HOME/python/django-apps.conf.d/$app"


  ! [ -e "$appconf/server.sh" ] && continue

  echo "location $user_uri/dj {"

  app_uri="$user_uri/dj/$app"

  [ -e "$appconf/nginx-extra.sh" ] && echo && \
    echo "# source: $appconf/nginx-extra.sh" && \
    . "$appconf/nginx-extra.sh"

  if [ -e "$appconf/nginx-default.sh" ]; then
    echo
    echo "# source: $appconf/nginx-default.sh"
    . "$appconf/nginx-default.sh" 
  else
    echo
    echo "# source: $base_path/dj/app.sh"
    . "$base_path/dj/app.sh"
  fi

  [ -e "$base_path/dj/extra.sh" ] && echo && \
    echo "# source: $base_path/dj/extra.sh" && \
    . "$base_path/dj/extra.sh"

  echo "}"
done
}

main
