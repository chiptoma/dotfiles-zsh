#!/usr/bin/env zsh
# ==============================================================================
# DATABASES REGISTRY
# PostgreSQL, MySQL, Redis, SQLite, MongoDB, InfluxDB.
# ==============================================================================

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_DB+=(
    'PSQL_HISTORY'        '$XDG_STATE_HOME/psql_history|psql'
    'PSQLRC'              '$XDG_CONFIG_HOME/pg/psqlrc|psql'
    'PGPASSFILE'          '$XDG_CONFIG_HOME/pg/pgpass|psql'
    'PGSERVICEFILE'       '$XDG_CONFIG_HOME/pg/pg_service.conf|psql'
    'MYSQL_HISTFILE'      '$XDG_STATE_HOME/mysql_history|mysql'
    'MYCLI_HISTFILE'      '$XDG_STATE_HOME/mycli_history|mycli'
    'REDISCLI_HISTFILE'   '$XDG_STATE_HOME/redis_history|redis-cli'
    'REDISCLI_RCFILE'     '$XDG_CONFIG_HOME/redis/redisclirc|redis-cli'
    'SQLITE_HISTORY'      '$XDG_STATE_HOME/sqlite_history|sqlite3'
    'MONGOSH_HOME'        '$XDG_CONFIG_HOME/mongosh|mongosh'
    'INFLUX_CLI_CONFIG'   '$XDG_CONFIG_HOME/influxdb/influx-cli.conf|influx'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.psql_history'   '$XDG_STATE_HOME/psql_history|Set PSQL_HISTORY|true|psql'
    '$HOME/.mysql_history'  '$XDG_STATE_HOME/mysql_history|Set MYSQL_HISTFILE|true|mysql'
    '$HOME/.mongosh'        '$XDG_CONFIG_HOME/mongosh|Set MONGOSH_HOME|true|mongosh'
    '$HOME/.rediscli_history' '$XDG_STATE_HOME/redis_history|Set REDISCLI_HISTFILE|true|redis-cli'
    '$HOME/.sqlite_history' '$XDG_STATE_HOME/sqlite_history|Set SQLITE_HISTORY|true|sqlite3'
)
