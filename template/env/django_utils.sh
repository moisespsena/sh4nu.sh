dj_load() {
  dj_app=$1

  if [ "$dj_app" = '' ]; then
    echo INVALID DJANGO APP NAME. >&2
    exit 1
  fi

  dj_app_path="$SNHM_HOME/python/django-apps/$dj_app"

  [ ! -e "$dj_app_path/manage.py" ] && echo "INVALID APP PATH. The $dj_app_/pathmanage.py file not found." >&2 && exit 1

  [ -e "$dj_app_path/env.sh" ] && . "$dj_app_path/env.sh"

  if [ "$DJANGO_SETTINGS_MODULE" = '' ]; then
    echo Auto detecting DJANGO_SETTINGS_MODULE and DJANGO_WSGI_MODULE...

    local main_module=$(grep DJANGO_SETTINGS_MODULE "$dj_app_path/manage.py" | \
	  perl -pe 's/^.+\W(\w+)\.settings.+$/\1/' | \
          grep -P '^[a-zA-Z]\w*$')

    if [ "$main_module" = '' ]; then
      echo 'Nao foi possivel identificar o modulo principal da aplicacao.
Certifique-se no arquivo '"$dj_app_path/manage.py"' haja uma linha parecida com "os.environ.setdefault("DJANGO_SETTINGS_MODULE", "youer_app_name.settings")' >&2
      exit 1
    fi

    export DJANGO_SETTINGS_MODULE=$main_module.settings
    export DJANGO_WSGI_MODULE=$main_module.wsgi
  fi

  export DJANGO_APP=$(echo "$DJANGO_SETTINGS_MODULE" | awk -F'.' '{print $1}')
}

dj_info() {
  echo DJANGO APP:
  echo -----------
  echo "dj_app=$dj_app"
  echo "dj_app_path=$dj_app_path"
  echo
  echo DJANGO ENVIROMENT VARIABLES:
  echo ----------------------------
  env | grep ^DJANGO_
}

dj_gun_info() {
  echo
  echo GUNICORN ENVIROMENT VARIABLES:
  echo ------------------------------
  env | grep ^GUNICORN_
  echo
}

dj_gun_info() {
  echo
  echo CELERY ENVIROMENT VARIABLES:
  echo ----------------------------
  env | grep ^CELERY_
  echo
}


dj_gun_exec() {
  sfx=$$

  [  "$DJ_NAME" != '' ] && sfx="$DJ_NAME"

  dj_gun_pidf="/run/$USER/snhm/dj-$dj_app-server-$sfx.pid"
  dj_gun_sockf="/run/$USER/snhm/dj-$dj_app-server-$sfx.sock"
  main_pidf="/run/$USER/snhm/dj-$dj_app-server-$sfx-main.pid"

  on_done rm -vf "$dj_gun_pidf" "$dj_gun_sockf"

  snhm_exec gunicorn $DJANGO_WSGI_MODULE:application --chdir "$dj_app_path" --pid "$dj_gun_pidf" --name="snhm-dj-$USER-$dj_app" -b "unix://$dj_gun_sockf" --log-level=info --log-file=- "${GUNICORN_ARGS[@]}"
}

dj_celery_exec() {
  sfx=$$

  [  "$DJ_NAME" != '' ] && sfx="$DJ_NAME"

  dj_celery_pidf="/run/$USER/snhm/dj-$dj_app-celery-$sfx.pid"
  main_pidf="/run/$USER/snhm/dj-$dj_app-celery-$sfx-main.pid"

  cd "$dj_app_path" || exit 1

  on_done rm -vf "$dj_celery_pidf"

  snhm_exec celery -A $DJANGO_APP worker -l info "${CELERY_ARGS[@]}"
}

