#!/bin/bash
S=$(realpath "$0")
RWORK=$(dirname $(dirname "$S"))

. "$RWORK/env.sh" || exit 1

load_confs () {
  if [ -e "$1" ]; then
    _cmt="$2"
    (ls "$1/"*.conf 2>/dev/null) | while read l; do echo "$_cmt## source: $l"; cat "$l"; echo; done
    (ls "$1/"*.sh 2>/dev/null) | while read l; do echo "$_cmt## source: $l"; . "$l"; echo; done
  fi
}

_ed() {
  . "$SNHM_HOME/default/conf.d/$1"
}


_setup() {
  user="$USER"
  home="$HOME"

  echo "cat > $TMPFILES_D_DIR/snhm-$USER.conf <<'EOF'"
  _ed tmpfiles.sh
  load_confs 'tmpfiles.conf.d'
  echo EOF

  echo "cat > $SUPERVISOR_CONF_D_DIR/snhm-$USER.conf <<'EOF'"
  _ed supervisor.sh
  load_confs 'supervisor.conf.d'
  echo EOF

  echo "cat > $PHP_FPM_POOL_D_DIR/snhm-$USER.conf <<'EOF'"
  _ed php-fpm.sh
  load_confs 'php-fpm.conf.d'
  echo EOF

  echo "cat > $NGINX_CONF_DIR/snhm/u/$USER.conf <<'EOF'"
  _ed nginx.sh
  load_confs 'nginx.conf.d'
  echo EOF

  echo "[ ! -e '/run/$USER/snhm' ] && mkdir -pv '/run/$USER/snhm' && chown -vR '$USER.$USER' '/run/$USER'"
}

_user_home() {
  eval echo ~"$1"
}

_ls_users() {
  local u=
  local h=

  while read u; do
    read h
    w="$h/.snhm"

    [ ! -e "$w/.env" ] && continue
    echo "$u"
  done < <(awk -F':' '{print $1"\n"$6}' /etc/passwd)
}

_init() {
  export SNHM_HOME="$HOME/.snhm"
  [ ! -d "$SCP_HOME" ] && mkdir -pv "$SNHM_HOME" || exit 1
  cd "$SNHM_HOME"
  echo "$RWORK" > .snhm_root
  echo 'bin
log
default
default/conf.d
default/conf.d/nginx
default/conf.d/nginx/static
default/conf.d/nginx/public
default/conf.d/nginx/dj
nginx.conf.d
php-fpm-pool.conf.d
python/django-apps.conf.d
python/django-apps
supervisor.conf.d
supervisor.conf.d/dj
tmpfiles.d
env
www/dj
' | while read l; do [ "$l" != '' ] && [ ! -e "snhm/$l" ] && mkdir -pv "$l" && touch "$l/.ignore"; done

  [ ! -e ".env" ] && echo '
export SNHM_HOME=$(dirname $(realpath "$BASH_SOURCE")) || exit 1
export SNHM_ROOT=$(cat "$SNHM_HOME/.snhm_root") || exit 1
. "$SNHM_ROOT/env.sh"
. "$SNHM_HOME/env/default.sh"
' > .env

  [ ! -e "$HOME/public_html" ] && mkdir -v "$HOME/public_html"
  [ ! -e "www/public" ] && (cd www && ln -vs "../../public_html" ./public)
  (cd www/public && [ ! -e ./static ] && mkdir -v ./static)
  [ ! -e "www/static" ] && (cd www && ln -vs "./public/static" ./static)

  (cd "$RWORK/template" && find . -type f | grep -v '.swp') | while read l; do
    l=${l##./}
    [ ! -e "$l" ] && ln -vs "$RWORK/template/$l" "$l"
  done

  return 0

}

_setup_root() {
  www="/var/www/u"

  [ ! -e "$www" ] && mkdir -p "$www"
  [ ! -e "$NGINX_CONF_DIR/snhm/u" ] && mkdir -pv "$NGINX_CONF_DIR/snhm/u"

  (ls "$RWORK/setup.d/"*.sh 2>/dev/null) | while read l; do
    . "$l"
  done

  _ls_users | while read u; do
    h=$(_user_home "$u")
    w="$h/.snhm"
    "$S" setup-code "$u"
    [ ! -e "$www/$u" ] && ln -vs "$w/www" "$www/$u"
  done

  echo "if [ -e '$APACHE_HOME' ]; then"
    echo "$APACHE_CONFIGURE_CMD"
    echo "  $APACHE_RESTART_CMD || exit \$?"
  echo fi

}

_init_user() {
  su - "$1" -c "$S init"
  return $?
}

if [ "$1" = 'init' ]; then
  [ "$USER" = 'root' ] && echo 'INVALID USER.' && exit 1
  _init
  exit $?
fi

if [ "$1" = 'update' ]; then
  while read u; do
    _init_user "$u"
  done < <(_ls_users)
  exit $?
fi

if [ "$1" = 'ls_users' ]; then
  if [ "$2" = '--home' ]; then
    while read u; do
      echo "$u:"$(_user_home "$u")
    done < <(_ls_users)
  else
    _ls_users
  fi
  exit $?
fi


if [ "$1" = 'init_user' ]; then
  _init_user "$2"
  exit $?
fi

if [ "$1" = 'setup-code' ]; then
  if [ "$USER" != 'root' ]; then
    cd ~
    cd .snhm || exit 1
    . ./.env || exit 1
    _setup
  else
    if [ "$2" != '' ]; then
      [ "$2" = 'root' ] && echo INVALID USER >&2 && exit 1
      su - "$2" -c "$S setup-code"
    else
      _setup_root
    fi
  fi
  exit $?
fi

if [ "$1" = 'setup' ]; then
  "$0" setup-code | bash
  exit $?
fi

if [ "$1" = 'setup-full' ]; then
  "$0" setup || exit $?
  "$0" ssl-generate || exit $?
  "$0" nginx-set-default || exit $?
  "$0" restart-services || exit $?
  echo setup full done.
  exit
fi



if [ "$1" = 'ssl-generate' ]; then
  certs_dir="$NGINX_CONF_DIR/snhm/certs"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$certs_dir/cert.key" -out "$certs_dir/cert.crt" || exit $?
  openssl dhparam -out "$certs_dir/dhparam.pem" 2048 || exit $?
  echo done.
  exit
fi

if [ "$1" = 'nginx-set-default' ]; then
    cd "$NGINX_CONF_DIR/sites-enabled" || exit $?
    rm -v default
    ln -s ../sites-available/snhm-default ./default
    ${NGINX_RESTART_CMD[@]}
    echo done.
    exit
fi

if [ "$1" = 'restart-services' ]; then
    eval "$NGINX_RESTART_CMD" || exit $?
    eval "$PHP_FPM_RESTART_CMD" || exit $?
    eval "$SUPERVISOR_CTL_UPDATE_CMD" || exit $?

    echo done.
    exit
fi
