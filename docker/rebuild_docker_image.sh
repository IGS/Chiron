#!/bin/bash

docker rmi -f jorvis/hmp-cloud-pilot
docker build --no-cache -t jorvis/hmp-cloud-pilot .
docker images

echo "If ready for release, run: docker tag <newest tag here> jorvis/hmp-cloud-pilot:latest"
echo "         docker push jorvis/hmp-cloud-pilot"
