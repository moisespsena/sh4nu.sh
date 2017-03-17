main() {
  nginx_snhm_site="$NGINX_CONF_DIR/sites-available/snhm-default"
  d=$(dirname ${BASH_SOURCE})
echo "
cp -vr $d/www/* /var/www
"
}

main
