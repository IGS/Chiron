#!/bin/bash

IMAGE_VERSION='1.1.0'

docker rmi -f umigs/chiron-metaviz
docker build --no-cache -t umigs/chiron-metaviz:latest -t umigs/chiron-metaviz:${IMAGE_VERSION} .
docker images


echo "If ready for release, run: "
echo "  docker push umigs/chiron-metaviz:latest"
echo "  docker push umigs/chiron-metaviz:${IMAGE_VERSION}"
