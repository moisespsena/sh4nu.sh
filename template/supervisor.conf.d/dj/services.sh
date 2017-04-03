cat <<EOF
[program:$(dj_supervisor_program $app)-services]
user=$USER
group=$USER
directory=$dj_app_path
command=$SNHM_HOME/bin/dj-app-services.sh $app
environment=USER="$USER",HOME="$HOME",DJ_NAME="main"
stdout_logfile=$SNHM_HOME/log/dj-$app-services.log
stdout_logfile_maxbytes=20MB
stdout_logfile_backups=2
pidfile=/run/$USER/shcp/dj-$app-services.pid
redirect_stderr=true
EOF

