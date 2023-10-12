# Automatically Redis Triggers & Functions Import

This directory provides an example of how to automatically import Triggers & Functions from JavaScript files with the *.js extension. These files are sourced from the triggers-functions directory. The Docker container named redis-cli, with its entrypoint set to tfunctions_load.sh, facilitates the import into the redis-stack-server database.

To initiate the Docker containers using Compose, execute:

```shell
docker compose up -d
```

To remove all containers and their associated images post-testing:

```shell
docker compose down --rmi all
```

## Docker Compose File Explanation:

The Docker Compose file orchestrates the setup of two services: `redis-stack-server` and `redis-cli.

- **redis-stack-server**: This is the main Redis server. It uses volumes to persist data and configuration. The environment variables set the username and password for the Redis instance. The health check ensures the Redis server is running and responsive.
- **redis-cli**: This container is responsible for importing the JavaScript triggers and functions into the Redis server. It waits until the `redis-stack-server` is healthy before starting, ensuring that the Redis server is ready to accept data.

```yaml
# Docker compose file for an example redis stack server
services:
    redis-stack-server:
        container_name: redis-stack-server
        volumes:
            - /tmp/docker/redis-stack-server/data/redis:/data/redis
            - ./redis-stack.conf:/etc/configuration/redis-stack.conf
            - ./users.acl:/etc/users.acl
        environment:
            - REDIS_USERNAME=ping
            - REDIS_PASSWORD=pong
        ports:
            - "6379:6379"
        restart: always
        image: redis/redis-stack-server:latest
        command: [ "redis-server", "etc/configuration/redis-stack.conf" ]
        healthcheck:
            test: "sh -c 'redis-cli --user $$REDIS_USERNAME --pass $$REDIS_PASSWORD --no-auth-warning ping'"
            timeout: 30s
            retries: 5
            start_period: 10s
    redis-cli:
        container_name: redis-cli
        environment:
            - REDIS_HOST=redis-stack-server
            - REDIS_PORT=6379
            - REDIS_USERNAME=import
            - REDIS_PASSWORD=triggersNfunctions
        depends_on:
            redis-stack-server:
                condition: service_healthy
        image: redis:latest
        volumes:
            - ./triggers-functions:/app/triggers-functions
            - ./tfunctions_load.sh:/app/tfunctions_load.sh
        entrypoint: [ "/app/tfunctions_load.sh" ]
```

## Loading Script Explanation:

This script checks for the presence of essential environment variables. If any are missing, it throws an error. It then iterates over all `*.js` files in the `triggers-functions` directory, importing them into the Redis server using the `redis-cli` command.

```bash
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
```

## Redis Stack Configuration Explanation:

This configuration file is for the Redis server. It specifies which modules to load, where to store data, and other essential settings. The `appendonly` mode ensures data persistence across restarts.

```text
# This is out redis configuration file. We are using it to load
# the modules, set the data directory and enable appendonly mode.
loadmodule /opt/redis-stack/lib/redisearch.so
loadmodule /opt/redis-stack/lib/redistimeseries.so
loadmodule /opt/redis-stack/lib/rejson.so
loadmodule /opt/redis-stack/lib/redisbloom.so
loadmodule /opt/redis-stack/lib/redisgears.so v8-plugin-path /opt/redis-stack/lib/libredisgears_v8_plugin.so

dir /data/redis

aclfile /etc/users.acl

appendonly yes
```

## ACL List Explanation:

The Access Control List (ACL) defines user permissions for the Redis server. The default user has no permissions. The developer user has access to all commands, while the `ping` and `import users have limited permissions tailored to their specific roles.

```text
user default off
user developer on >123456 ~* allcommands
user ping on >pong nocommands +ping
user import on >triggersNfunctions nocommands +tfunction|load
```

By following this guide and utilizing the provided examples, you can seamlessly automate the import of Triggers & Functions into your Redis database. This approach not only streamlines the setup process but also ensures a consistent and efficient data import workflow.