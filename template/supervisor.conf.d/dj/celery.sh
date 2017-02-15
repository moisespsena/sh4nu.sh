cat <<EOF
[program:$(dj_supervisor_program $app)-celery]
user=$USER
group=$USER
directory=$dj_app_path
command=$SNHM_HOME/bin/dj-app-celery-worker.sh $app
environment=USER="$USER",HOME="$HOME",DJ_NAME="main"
stdout_logfile=$SNHM_HOME/log/dj-$app-celery.log
stdout_logfile_maxbytes=20MB
stdout_logfile_backups=2
pidfile=/run/$USER/snhm/dj-celery-default.pid
redirect_stderr=true
numprocs=1
priority=1000
EOF
