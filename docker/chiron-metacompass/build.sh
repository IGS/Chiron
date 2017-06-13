#!/bin/bash

IMAGE_VERSION='1.0.0'

docker rmi -f umigs/chiron-metacompass
docker build --no-cache -t umigs/chiron-metacompass:latest -t umigs/chiron-metacompass:${IMAGE_VERSION} .
docker images

echo "If ready for release, run: "
echo "  docker push umigs/chiron-metacompass:latest"
echo "  docker push umigs/chiron-metacompass:${IMAGE_VERSION}"

