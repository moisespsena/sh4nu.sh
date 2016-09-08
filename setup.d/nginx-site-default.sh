main() {
  nginx_shcp_site="$NGINX_CONF_DIR/sites-available/shcp-default"
  echo "[ ! -e '$nginx_shcp_site' ] && cat > '$nginx_shcp_site' <<'EOF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  include shcp/shcp.conf;
}
EOF

cat > $NGINX_CONF_DIR/shcp/shcp.conf <<'EOF'
  root $WWW_DIR;

  index index.php index.html index.htm index.nginx-debian.html;

  server_name _;

  include shcp/u/*.conf;

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
