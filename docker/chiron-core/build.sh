#!/bin/bash

docker rmi -f umigs/chiron-core
docker build --no-cache -t umigs/chiron-core .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-core:latest"
echo "  docker push umigs/chiron-core"
