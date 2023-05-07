#!/bin/bash
# Developer Note: Run this script in the /workspace/development directory

export NVM_DIR=~/.nvm
# shellcheck disable=SC1091
source $NVM_DIR/nvm.sh

sudo apt -qq update && sudo apt -qq install jq -y

get_client_apps() {
  apps=$(jq ".\"$client\"" apps.json)

  if [ "$apps" == "null" ]; then
    echo "No apps found for $client"
    exit 1
  fi
}

validate_bench_exists() {
  dir="$(pwd)/$bench_name"
  if [ -d "$dir" ]; then
    echo "Bench already exists. Only site will be created"
    is_existing_bench=true
  else
    is_existing_bench=false
  fi
}

validate_branch() {
  if [ "$app" == "frappe" ] || [ "$app" == "erpnext" ]; then
    if [ "$branch" != "develop" ] && [ "$branch" != "version-14" ] && [ "$branch" != "version-13" ]; then
      echo "Branch should be one of develop or version-14 or version-13"
      exit 1
    fi
  fi
}

validate_site() {
  site_name+=".localhost"
  if [[ ! "$site_name" =~ ^.*\.localhost$ ]]; then
    echo "Site name should end with .localhost"
    exit 1
  fi

  if [ "$is_existing_bench" = true ]; then
    validate_site_exists
  fi
}

validate_site_exists() {
  dir="$(pwd)/$bench_name/sites/$site_name"
  if [ -d "$dir" ]; then
    echo "Site already exists. Exiting"
    exit 1
  fi
}

validate_app_exists() {
  dir="$(pwd)/apps/$app"
  if [ -d "$dir" ]; then
    echo "App $app already exists."
    is_app_installed=true
  else
    is_app_installed=false
  fi
}

add_fork() {
  dir="$(pwd)/apps/$app"
  if [ "$fork" != "null" ]; then
    git -C "$dir" remote add fork "$fork"
  fi
}

install_apps() {
  initialize_bench=$1

  for row in $(echo "$apps" | jq -r '.[] | @base64'); do
    # helper function to retrieve values from dict
    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }

    app=$(_jq '.name')
    branch=$(_jq '.branch')
    upstream=$(_jq '.upstream')
    fork=$(_jq '.fork')

    if [ "$initialize_bench" = true ] && [ "$app" == "frappe" ]; then
      init_bench
    fi
    if [ "$initialize_bench" = false ]; then
      get_apps_from_upstream
    fi
  done
}

init_bench() {
  echo "Creating bench $bench_name"

  if [ "$branch" == "develop" ] || [ "$branch" == "version-14" ]; then
    python_version=python3.10
    PYENV_VERSION=3.10.5
    NODE_VERSION=v16
  elif [ "$branch" == "version-13" ]; then
    python_version=python3.9
    PYENV_VERSION=3.9.9
    NODE_VERSION=v14
  fi

  nvm use "$NODE_VERSION"
  PYENV_VERSION="$PYENV_VERSION" bench init --skip-redis-config-generation --frappe-branch "$branch" --python "$python_version" "$bench_name"
  cd "$bench_name" || exit

  echo "Setting up config"

  bench set-config -g db_type "$db_type"
  bench set-config -g db_host "$db_host"
  bench set-config -g db_port "$db_port"
  bench set-config -g db_name "$db_name"
  bench set-config -g db_password "$db_root_password"
  bench set-config -g db_ssl_mode "$db_ssl_mode"
  bench set-config -g db_ssl_ca "$db_ssl_ca"
  # bench set-config -g db_ssl_cert "$db_ssl_cert"
  # bench set-config -g db_ssl_key "$db_ssl_key"
  bench set-config -g redis_cache "${redis_cache}"
  bench set-config -g redis_queue "${redis_queue}"
  bench set-config -g redis_socketio "${redis_socketio}"

  if [ "$db_type" == "postgres" ]; then
    bench config set-common-config -c root_login "$db_root_user"
    bench config set-common-config -c root_password "$db_root_password"
  fi

  ./env/bin/pip install honcho
}

get_apps_from_upstream() {
  validate_app_exists
  if [ "$is_app_installed" = false ]; then
    bench get-app --branch "$branch" --resolve-deps "$app" "$upstream" && add_fork
  fi

  if [ "$app" != "frappe" ]; then
    all_apps+=("$app")
  fi
}

echo "Client Name (from apps.json file)?"
read -r client && client=${client:-develop_client} && get_client_apps

echo "Bench Directory Name? (give name of existing bench to just create a new site) (default: envsage-bench)"
read -r bench_name && bench_name=${bench_name:-envsage-bench} && validate_bench_exists

echo "Admin Password? (default: admin)"
read -r admin_password && admin_password=${admin_password:-admin}

echo "DB Type? (default: postgres)"
read -r db_type && db_type=${db_type:-postgres}

# echo "DB Port? (default: 3306 (ie. default mariadb port))"
# read -r db_port && db_host=${db_host:-3306}
echo "DB Port? (default: 14799)"
read -r db_port && db_port=${db_port:-14799}

echo "DB CA Certificate PATH? (default: /workspace/development/ssl/ca.pem)"
read -r db_ssl_ca && db_ssl_ca=${db_ssl_ca:-"/workspace/development/ssl/ca.pem"}

echo "DB SSL Mode? (default: require)"
read -r db_ssl_mode && db_ssl_mode=${db_ssl_mode:-"require"}

echo "DB Name? (default: defaultdb)"
read -r db_name && db_name=${db_name:-defaultdb}

echo "Site Name? (default: site1)"
read -r site_name && site_name=${site_name:-site1} && validate_site

echo "DB Host? (default: postgresql)"
read -r db_host && db_host=${db_host:-postgresql}
# echo "DB Host? (default: next-orbit-pg-db-next-orbit.aivencloud.com)"
# read -r db_host && db_host=${db_host:-"next-orbit-pg-db-next-orbit.aivencloud.com"}

echo "DB User? (default: postgres)"
read -r db_root_user && db_root_user=${db_root_user:-postgres}

echo "DB Password? (default: 123)"
read -r db_root_password && db_root_password=${db_root_password:-123}

echo "Redis Cache Host? (default: redis://redis-cache:6379)"
read -r redis_cache && redis_cache=${redis_cache:-"redis://redis-cache:6379"}

echo "Redis Queue Host? (default: redis://redis-queue:6379)"
read -r redis_queue && redis_queue=${redis_queue:-"redis://redis-queue:6379"}

echo "Redis SocketIO Host? (default: redis://redis-socketio:6379)"
read -r redis_socketio && redis_socketio=${redis_socketio:-"redis://redis-socketio:6379"}

if [ "$is_existing_bench" = true ]; then
  cd "$bench_name" || exit
else
  install_apps true
fi

echo "Getting apps from upstream for $client"
all_apps=() && install_apps false

echo "Creating site $site_name"
if [ "$db_type" == "postgres" ]; then
    bench new-site "$site_name" --db-type postgres --db-host "$db_host" --db-name "$db_name" --db-port "$db_port" --db-password "$db_root_password" --db-root-username "$db_root_user" --db-root-password "$db_root_password" --admin-password "$admin_password"
else
    bench new-site "$site_name" --mariadb-root-password "$db_root_password" --admin-password "$admin_password" --no-mariadb-socket
fi


echo "Installing apps to $site_name"
bench --site "$site_name" install-app "${all_apps[@]}"

bench --site "$site_name" set-config developer_mode 1
bench --site "$site_name" clear-cache
