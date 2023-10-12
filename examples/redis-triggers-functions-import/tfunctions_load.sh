#!/usr/bin/env sh
set -e

# Überprüfen, ob die erforderlichen Umgebungsvariablen gesetzt sind
[ -z "$REDIS_HOST" ] && echo "Error: REDIS_HOST is not set." && exit 1
[ -z "$REDIS_PORT" ] && echo "Error: REDIS_PORT is not set." && exit 1
[ -z "$REDIS_USERNAME" ] && echo "Error: REDIS_USERNAME is not set." && exit 1
[ -z "$REDIS_PASSWORD" ] && echo "Error: REDIS_PASSWORD is not set." && exit 1

for script in /app/triggers-functions/*.js; do
    if [ -f "$script" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --user "$REDIS_USERNAME" --pass "$REDIS_PASSWORD" --no-auth-warning -x TFUNCTION LOAD < "$script"
    else
        echo "File not found: $script"
    fi
done