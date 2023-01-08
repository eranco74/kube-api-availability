#!/bin/bash

if kubectl get nodes &> /dev/null; then
  status="available"
  available_start_time=$(date +%s)
else
  status="unavailable"
  unavailable_start_time=$(date +%s)
fi

# Create an empty data.json file
echo '[{"group": "apiserver", "data":[]}]' > data.json

echo "Start serving on http://localhost:8080"
python -m http.server 8080 &

# Add an entry to the data.json
function addRecord(){
  jq -r --arg  status "$1" --arg start `date -d @$2 +%Y-%m-%dT%H:%M:%SZ` --arg finish `date -d @$3 +%Y-%m-%dT%H:%M:%SZ` \
  '.[0].data += [{"label": "kube-apiserver",
        "data": [
          {
          "timeRange": [
            $start,
            $finish
          ],
          "val": $status
          }
        ]
    }]' data.json > tmp.json
    mv -f tmp.json data.json   
    echo "Updated data.json"
}

while true
do
  if kubectl  get --raw='/readyz' &> /dev/null; then
    # If the API server is available, update the status and time range
    if [[ $status == "unavailable" ]]; then
      # If the API server was previously unavailable, set the available_start_time and record an unavailable entry
      available_start_time=$(date +%s)
      addRecord "Unavailable" $unavailable_start_time $available_start_time
    fi
    # don't forget to set the status
    status="available"
  else
    # If the API server is unavailable
    if [[ $status == "available" ]]; then
      # If the API server was previously available, set the unavailable_start_time and record an available entry
      unavailable_start_time=$(date +%s)
      addRecord "Available" $available_start_time $unavailable_start_time
    fi
    # don't forget to set the status
    status="unavailable"
  fi
  # Sleep for 1 second before checking again
  sleep 1
done

# Output the time range(s)
echo "Time range(s) when the Kubernetes API server was unavailable:"
echo "$time_range"

