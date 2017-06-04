#!/bin/bash

docker rmi -f umigs/chiron-metacompass
docker build --no-cache -t umigs/chiron-metacompass .
docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-metacompass:latest"
echo "  docker push umigs/chiron-metacompass"
