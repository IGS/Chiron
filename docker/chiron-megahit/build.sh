#!/bin/bash

IMAGE_VERSION='1.0.0'

docker rmi -f umigs/chiron-megahit
docker build --no-cache -t umigs/chiron-megahit:latest -t umigs/chiron-megahit:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-megahit:latest"
echo "  docker push umigs/chiron-megahit:${IMAGE_VERSION}"

