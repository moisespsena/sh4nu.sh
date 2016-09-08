TMPFILES_D_DIR="/etc/tmpfiles.d"

NGINX_CONF_DIR="/etc/nginx"
NGINX_RESTART_CMD="service nginx restart"

SUPERVISOR_CONF_D_DIR="/etc/supervisor/conf.d"
SUPERVISOR_RESTART_CMD="service supervisor restart"
SUPERVISOR_CTL_UPDATE_CMD="supervisorctl update"

PHP_FPM_RESTART_CMD="service php7.0-fpm restart"
PHP_FPM_POOL_D_DIR="/etc/php/7.0/fpm/pool.d"
PHP_FPM_DEFAULT_SOCK_FILE="/var/run/php/php7.0-fpm.sock"

WWW_DIR="/var/www"

APACHE_DEFAULT_PORT=81
APACHE_HOME="/etc/apache2"
APACHE_RESTART_CMD="service apache2 restart"
APACHE_CONFIGURE_CMD="
perl -i -pe 's/Listen 80/Listen $APACHE_DEFAULT_PORT/g'  '$APACHE_HOME/ports.conf' || exit \$?
a2enmod userdir || exit \$?
a2enmod rewrite || exit \$?

echo '
<IfModule mod_userdir.c>
	UserDir public_html
	UserDir disabled root

	<Directory /home/*/public_html>
		AllowOverride All
		Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
        Order allow,deny
        allow from all

		<Limit GET POST OPTIONS>
			Require all granted
		</Limit>
		<LimitExcept GET POST OPTIONS>
			Require all denied
		</LimitExcept>
	</Directory>
</IfModule>
' > '$APACHE_HOME/mods-available/userdir.conf' || exit 1
"

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
