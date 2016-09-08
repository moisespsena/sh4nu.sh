
main() {
  php_uri="$user_uri/php"

  echo "location $php_uri {"

  local base_path=$(dirname "$BASH_SOURCE")

  if [ -e "$base_path/php" ]; then
   (ls -1 "$base_path/php/"*.sh 2>/dev/null) | while read l; do
      echo "# source: $l"
    done
  fi

  echo "
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/$user/shcp/php-fpm.sock;
  }

  if (-f \"\$request_filename/index.php\") {
    rewrite (.+)/$ \$1/index.php last;
  }

  try_files \$uri \$uri/ =404;

  break;
}"
}

main
