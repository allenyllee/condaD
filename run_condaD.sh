#!/bin/bash
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -


# set .docker.xauth after login, becasue /tmp will be deleted everytime system startup
# filesystem - How is the /tmp directory cleaned up? - Ask Ubuntu 
# https://askubuntu.com/questions/20783/how-is-the-tmp-directory-cleaned-up
# 
tr '\n' '\000' < ~/.profile | sudo tee ~/.profile >/dev/null
sed -i 's|\x00XAUTH=.*-\x00|\x00|' ~/.profile
tr '\000' '\n' < ~/.profile | sudo tee ~/.profile >/dev/null
echo "XAUTH=/tmp/.docker.xauth; touch $XAUTH; xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -" >> ~/.profile
source ~/.profile


PSWD=$1
NOTEBOOK_DIR=$2

docker run -ti \
    --name anaconda \
    --publish 8889:8888 \
    --env DISPLAY=$DISPLAY \
    --env XAUTHORITY=$XAUTH \
    --env PASSWORD=$PSWD \
    --volume $XSOCK:$XSOCK \
    --volume $XAUTH:$XAUTH \
    --volume $NOTEBOOK_DIR:/opt/notebooks \
    --restart always \
    allenyllee/condad:latest
