# To Initialize

# We are using Release v1.1.1 Version.
nvm use v18

PYENV_VERSION=3.11.4 bench init --skip-redis-config-generation --frappe-branch v1.1.1 --frappe-path https://github.com/akash-m-envsage/frappe.git frappe-bench --apps_path apps.json

cd frappe-bench

bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-socketio:6379

# To create new sites

bench new-site <site_name>.localhost --mariadb-root-password 123 --admin-password admin --no-mariadb-socket

NOTE: replace <site_name> with your site_name

# Set bench developer mode on the new site
bench --site <site_name>.localhost set-config developer_mode 1
bench --site <site_name>.localhost clear-cache

# Get App Example
bench get-app --branch version-12 https://github.com/myusername/myapp # use this as example

# Install App Example
bench --site <site_name>.localhost install-app app1
bench --site <site_name>.localhost install-app app2
bench --site <site_name>.localhost install-app app3

# Update max file size to 1gb (value in bytes)
bench --site <site_name>.localhost set-config max_file_size 1000000000

# CORS
bench set-config -g allow_cors "*"
bench --site <site_name>.localhost set-config allow_cors "*"

# Configure SES email
https://discuss.frappe.io/t/how-to-configure-email-account-with-amazon-ses-smtp-credentials/95365/2