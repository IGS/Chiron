#!/bin/bash

docker rmi -f umigs/chiron-qiime2
docker build --no-cache -t umigs/chiron-qiime2 .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-qiime2:latest"
echo "  docker push umigs/chiron-qiime2"
