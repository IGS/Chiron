#!/bin/bash

IMAGE_VERSION='1.0.2'

docker rmi -f umigs/chiron-valet
docker build --no-cache -t umigs/chiron-valet:latest -t umigs/chiron-valet:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-valet:latest"
echo "  docker push umigs/chiron-valet:${IMAGE_VERSION}"
