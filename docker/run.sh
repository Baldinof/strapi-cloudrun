#!/bin/bash
set -e

# Restore the database if it does not already exist.
if [ -f "${DATABASE_FILENAME}" ]; then
	echo "Database already exists, skipping restore"
else
	echo "No database found, restoring from replica if exists"
	litestream restore -v -if-replica-exists -o "${DATABASE_FILENAME}" "${REPLICA_URL}"
fi

# Run litestream with your app as the subprocess.
exec litestream replicate -trace /dev/stderr -exec "yarn start"
