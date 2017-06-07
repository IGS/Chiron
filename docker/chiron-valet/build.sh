#!/bin/bash

docker rmi -f umigs/chiron-valet
docker build --no-cache -t umigs/chiron-valet .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-valet:latest"
echo "  docker push umigs/chiron-valet"
