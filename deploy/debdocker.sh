#!/bin/bash
# $1 build dir

tdir=$1
exit 0

sudo docker pull ubuntu:rolling
sudo docker run --name docker_deb_build --rm -it -v "$tdir:/debbuild" "ubuntu:rolling" bash