#!/bin/bash

docker rmi -f umigs/chiron-phlan
docker build --no-cache -t umigs/chiron-phlan .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-phlan:latest"
echo "  docker push umigs/chiron-phlan"
