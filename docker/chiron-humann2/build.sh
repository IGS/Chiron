#!/bin/bash

docker rmi -f umigs/chiron-humann2
docker build --no-cache -t umigs/chiron-humann2 .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-humann2:latest"
echo "  docker push umigs/chiron-humann2"
