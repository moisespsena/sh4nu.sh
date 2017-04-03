
main() {
  local static_uri="$user_uri/static"

  echo "location $static_uri {"
  echo

  local base_path=$(dirname "$BASH_SOURCE")

  if [ -e "$base_path/static" ]; then
   (ls -1 "$base_path/static/"*.sh 2>/dev/null) | while read l; do
      echo "# START-SOURCE: $l"
      . "$l" || exit $?
      echo "# END-SOURCE: $l"
    done
  fi

  echo "
  try_files \$uri \$uri/ =404;

  break;
  "
  echo '}'
}

main
