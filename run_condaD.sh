#!/bin/bash

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

PSWD=$1

docker run -ti \
    --name anaconda \
    --publish 8889:8888 \
    --env DISPLAY=$DISPLAY \
    --env XAUTHORITY=$XAUTH \
    --env PASSWORD=$PSWD \
    --volume $XSOCK:$XSOCK \
    --volume $XAUTH:$XAUTH \
    --volume $PWD/project/jupyter/notebooks:/opt/notebooks \
    allenyllee/condad:latest