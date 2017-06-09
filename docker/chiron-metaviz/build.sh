#!/bin/bash

sudo docker rmi -f umigs/chiron-metaviz
sudo docker build --no-cache -t umigs/chiron-metaviz .
sudo docker images

echo "If ready for release, run: "
echo "  docker tag <newest tag here> umigs/chiron-metaviz:latest"
echo "  docker push umigs/chiron-metaviz"
