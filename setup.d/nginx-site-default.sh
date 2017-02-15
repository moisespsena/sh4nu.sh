main() {
  nginx_snhm_site="$NGINX_CONF_DIR/sites-available/snhm-default"
  echo "[ ! -e '$nginx_snhm_site' ] && cat > '$nginx_snhm_site' <<'EOF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

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

  location /sys/phpMyAdmin {
    rewrite ^/sys/* /sys/phpmyadmin last;
  }

  location /sys/pma {
    rewrite ^/sys/* /sys/phpmyadmin last;
  }

  location /sys/pga {
    rewrite ^/sys/* /sys/phppgadmin/index.php last;
  }

  location /sys/ {
    try_files \$uri $uri/ =404;

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
"
}

main
