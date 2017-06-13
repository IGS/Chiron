#!/bin/bash

IMAGE_VERSION='1.0.0'

docker rmi -f umigs/chiron-humann2
docker build --no-cache -t umigs/chiron-humann2:latest -t umigs/chiron-humann2:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-humann2:latest"
echo "  docker push umigs/chiron-humann2:${IMAGE_VERSION}"

