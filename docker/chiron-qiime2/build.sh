#!/bin/bash

docker rmi -f jorvis/chiron-qiime2
docker build --no-cache -t jorvis/chiron-qiime2 .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> jorvis/chiron-qiime2:latest"
echo "  docker push jorvis/chiron-qiime2"
