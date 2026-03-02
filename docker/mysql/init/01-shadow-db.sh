#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${MYSQL_DATABASE:-nexus-support}"
DB_USER="${MYSQL_USER:-nexus_support}"
SHADOW_DB_NAME="${DB_NAME}_shadow"

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${SHADOW_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${SHADOW_DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL
