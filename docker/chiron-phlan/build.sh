#!/bin/bash

docker rmi -f umigs/chiron-metaphlan2
docker build --no-cache -t umigs/chiron-metaphlan2 .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-metaphlan2:latest"
echo "  docker push umigs/chiron-metaphlan2"
