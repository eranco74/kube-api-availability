#!/bin/bash

set -euo pipefail

# Make sure we don't leave a running process behind
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

DATA_DIR=${SCRIPT_DIR}/static
DATA_FILE=${DATA_DIR}/data.json

mv $DATA_FILE ${DATA_FILE}_old_$(date -u +%Y-%m-%dT%H:%M:%S%Z) || true
echo '[]' > $DATA_FILE;

function record() {
	jq --arg current_status "$1" -f $SCRIPT_DIR/query.jq $DATA_FILE | sponge $DATA_FILE
}

echo "Start serving on http://localhost:8080"
python -m http.server 8080 --directory $DATA_DIR &

while true; do
    if kubectl  get --raw='/readyz' &> /dev/null; then
        record "Available"
    else
        record "Unavailable"
    fi
    sleep 1
done
