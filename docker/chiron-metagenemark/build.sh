#!/bin/bash

IMAGE_VERSION='1.0.0'

docker rmi -f umigs/chiron-metagenemark
docker build -t umigs/chiron-metagenemark:latest -t umigs/chiron-metagenemark:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-metagenemark:latest"
echo "  docker push umigs/chiron-metagenemark:${IMAGE_VERSION}"

