dj_apps_d="$SNHM_HOME/python/django-apps"
dj_apps_conf_d="$dj_apps_d.conf.d"

[ ! -e "$dj_apps_d" ] && exit 0

dj_supervisor_program() {
  echo "$USER-dj-$1"
}

_dj_app_conf() {
  (ls -1 "$dj_app_conf_d/"*.sh 2>/dev/null) | while read f; do
    echo "## source: $dj_app_conf_d/$1.sh" && echo && \
    . "$f" && echo
  done
}

ls -1 "$dj_apps_d" | while read app; do
  dj_app_path="$dj_apps_d/$app"
  dj_app_conf_d="$dj_apps_conf_d/$app"

  _dj_app_conf
done
