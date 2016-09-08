echo "
location $app_uri {
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  # proxy_set_header X-Forwarded-Proto https;
  proxy_set_header Host \$http_host;
  proxy_redirect off;
  proxy_buffering off;

  if ( !-f \$request_filename) {
    proxy_pass http://unix:/run/$user/shcp/dj-$app-server-main.sock;
  }

  error_page 500 502 503 504 $app_uri/static/500.html;
  break;
}
"
