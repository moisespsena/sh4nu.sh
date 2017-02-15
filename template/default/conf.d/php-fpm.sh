cat <<EOF
[snhm-$USER-default]
user=$USER
group=$USER
listen=/run/$USER/snhm/php-fpm.sock
listen.owner=www-data
listen.group=www-data
pm=dynamic
pm.max_children=5
pm.start_servers=2
pm.min_spare_servers=1
pm.max_spare_servers=3
chdir=$SNHM_HOME/www/php
EOF
