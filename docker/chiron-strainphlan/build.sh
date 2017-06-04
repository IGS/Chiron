#!/bin/bash

docker rmi -f jorvis/chiron-strainphlan
docker build --no-cache -t jorvis/chiron-strainphlan .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> jorvis/chiron-strainphlan:latest"
echo "  docker push jorvis/chiron-strainphlan"
