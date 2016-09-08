export SHCP_SUPERVISOR_CONF_D="$SHCP_HOME/supervisor.conf.d"

set_global() {
   local arg="$1"
   IFS="" read $arg <<EOF
$2
EOF
}

load_env() {
  var="_shcp_env_loaded_$1"
  v="${!var}"

  if [ "$v" = '' ]; then
    set_global "_shcp_env_loaded_$1" 1
    . "$SHCP_HOME/env/$1.sh" || exit 1
  fi
}

pre_fn()
{
    local name=$1
    shift
    local body="$@"
    eval "$(echo "${name}(){"; echo ${body}; declare -f ${name} | tail -n +3)"
}

# Syntax: append_to_function <name> [statements...]
function post_fn()
{
    local name=$1
    shift
    local body="$@"
    eval "$(declare -f ${name} | head -n -1; echo ${body}; echo '}')"
}

on_done_() {
  echo -n
}

on_done() {
  post_fn on_done_ "$@"
}

kill_jobs() {
  for job in $(jobs -p); do
    kill -s SIGTERM $job > /dev/null 2>&1 || \
      (sleep 10 && kill -9 $job > /dev/null 2>&1 &)
  done
}

kill_jobs_and_done() {
  kill_jobs
  sleep 1
  on_done_
  echo done.
  echo
}

trap_quit() {
  kill_jobs_and_done
}

catch_signals() {
  trap trap_quit EXIT
}

shcp_exec() {
  args=( )

  while [ "$1" != "" ]; do
    args+=( "$1" )
    shift
  done;

  echo COMMAND:
  echo --------
  printf "%s\n" "${args[@]}"
  echo =================

  catch_signals

  if [ ! -z "$main_pidf" ]; then
    echo $$ > $main_pidf
    on_done rm -vf "$main_pidf"
  fi

  exec "${args[@]}" &

  pid=$!

  echo PID: $pid
  echo =================

  wait $pid

  s=$?
  echo "EXIT STATUS: $s"

  exit $s
}
