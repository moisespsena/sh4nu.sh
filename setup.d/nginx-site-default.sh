main() {
  nginx_snhm_site="$NGINX_CONF_DIR/sites-available/snhm-default"
echo "[ ! -e '$nginx_snhm_site' ] && cat > '$nginx_snhm_site' <<'EOF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  include snhm/snhm.conf;
}

server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  server_name _;
  
  include snhm/ssl.conf;
  include snhm/ssl-params.conf;
  include snhm/snhm.conf;
}

EOF

cat > $NGINX_CONF_DIR/snhm/snhm.conf <<'EOF'
  root $WWW_DIR;

  index index.php index.html index.htm index.nginx-debian.html;
  
  access_log off;
  error_log  /var/log/nginx/snhm-error.log;

  server_name _;

  include snhm/u/*.conf;

  charset   utf-8;

  gzip on;
  gzip_vary on;
  gzip_disable "msie6";
  gzip_comp_level 6;
  gzip_min_length 1100;
  gzip_buffers 16 8k;
  gzip_proxied any;
  gzip_types
    text/plain
    text/css
    text/js
    text/xml
    text/javascript
    application/javascript
    application/x-javascript
    application/json
    application/xml
    application/xml+rss;

  autoindex on;

  client_max_body_size 20m;

  location ~ /\.ht {
    deny all;
  }

  location /sys/ {
    location ~ \.php$ {
      try_files \$uri =404;
      fastcgi_pass unix:$PHP_FPM_DEFAULT_SOCK_FILE;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME \$request_filename;
      include /etc/nginx/fastcgi_params;
      fastcgi_param PATH_INFO \$fastcgi_script_name;
      fastcgi_buffer_size 128k;
      fastcgi_buffers 256 4k;
      fastcgi_busy_buffers_size 256k;
      fastcgi_temp_file_write_size 256k;
      fastcgi_intercept_errors on;
    }

    if (-f \"\$request_filename/index.php\") {
      rewrite (.+)/$ \$1/index.php last;
    }
  }

  location /apache {
    proxy_set_header X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header Host \$host;
    proxy_pass http://127.0.0.1:$APACHE_DEFAULT_PORT/;
  }
EOF


  certs_dir=$NGINX_CONF_DIR/snhm/certs

  if [ ! -e \$certs_dir ]; then
    mkdir \$certs_dir || exit $?
  fi

  if [ ! -e "$NGINX_CONF_DIR/snhm/ssl.conf" ]; then
    cat > "$NGINX_CONF_DIR/snhm/ssl.conf" <<'EOF'
ssl_certificate snhm/certs/cert.crt;
ssl_certificate_key snhm/certs/cert.key;
EOF
  fi

  if [ ! -e '$NGINX_CONF_DIR/snhm/ssl-params.conf' ]; then
    cat > '$NGINX_CONF_DIR/snhm/ssl-params.conf' <<'EOF'
# https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04
# from https://cipherli.st/
# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers \"EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH\";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
# add_header Strict-Transport-Security \"max-age=63072000; includeSubdomains; preload\";
add_header Strict-Transport-Security \"max-age=63072000; includeSubdomains\";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;

ssl_dhparam snhm/certs/dhparam.pem;
EOF
fi
 
"
}

main
