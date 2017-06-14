#!/bin/bash

IMAGE_VERSION='1.1.2'

docker rmi -f umigs/chiron-core
docker build --no-cache -t umigs/chiron-core:latest -t umigs/chiron-core:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-core:latest"
echo "  docker push umigs/chiron-core:${IMAGE_VERSION}"

