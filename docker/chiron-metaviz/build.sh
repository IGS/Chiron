#!/bin/bash

docker rmi -f jorvis/chiron-metaviz
docker build --no-cache -t jorvis/chiron-metaviz .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> jorvis/chiron-metaviz:latest"
echo "  docker push jorvis/chiron-metaviz"
