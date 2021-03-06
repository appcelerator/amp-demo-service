#!/bin/bash

echo "CONSUL: "$CONSUL
echo "DEPENDENCIES: "$DEPENDENCIES
if [ -z "$CONSUL" ]; then
  exec node dist/app.js
else
  #update containerpilot conffile
  sed -i "s/\[consul\]/$CONSUL/g" /etc/containerpilot.json
  sed -i "s/\[loglevel\]/$CP_LOG_LEVEL/g" /etc/containerpilot.json
  sed -i "s/\[poll\]/$CP_POLL/g" /etc/containerpilot.json
  sed -i "s/\[ttl\]/$CP_TTL/g" /etc/containerpilot.json
  echo ---------------------------------------------------------------------------
  echo containerPilot conffile
  cat /etc/containerpilot.json
  echo ---------------------------------------------------------------------------

  while true
  do
    ready=0
    while [ "$ready" != "1" ]
      do
      ready=1
      for service in $DEPENDENCIES
      do
        status=$(curl --max-time 3 -s http://$CONSUL/v1/health/checks/$service)
        if [[ $status =~ ^.*\"Status\":\"passing\" ]]; then
          echo $service" is ready"
        else
          echo $service" is not yet ready"
          ready=0
        fi
      done
      if [ "$ready" == "0" ]; then
        echo "Waiting for dependencies"
        sleep 10
      fi
    done
    sleep 3
    echo "All dependencies are ready"
    /bin/containerpilot node dist/app.js
  done
fi
