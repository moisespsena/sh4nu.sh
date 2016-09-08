
main() {
  user_uri="/u/$user"

  echo "location $user_uri {"

  local base_path=$(dirname "$BASH_SOURCE")

  if [ -e "$base_path/nginx" ]; then
    ls -1 "$base_path/nginx/"*.sh | while read l; do
      echo
      echo "# source: $l"
      echo
      . "$l" || exit 1
    done
  fi

  echo "}"
}

main
