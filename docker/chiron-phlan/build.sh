#!/bin/bash

IMAGE_VERSION='1.0.0'

docker rmi -f umigs/chiron-phlan
docker build --no-cache -t umigs/chiron-phlan:latest -t umigs/chiron-phlan:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-phlan:latest"
echo "  docker push umigs/chiron-phlan:${IMAGE_VERSION}"
