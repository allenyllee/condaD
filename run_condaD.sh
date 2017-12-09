#!/bin/bash

# Usage
#
# ./run_condad.sh [password] [notebook_dir] [use_gpu]
#
#       [password] is the password of your jupyter notebook.
#       [notebook_dir] is the local dir your notebook files located
#       [use_gpu] is to specify if gpu support image to use or not, if yes, just type gpu, or left it blank.
#
# After container started, just open
#       http://localhost:8889 (default image) or
#       http://localhost:8890 (gpu support image)
# Also, you can ssh into container with port 66 (for defalut image) or port 67 (for gpu image)
#   ex:
#       ssh -X -t root@localhost -p 66
#       ssh -X -t root@localhost -p 67



PSWD=$1
NOTEBOOK_DIR=$2
USE_GPU=$3


if [ "$USE_GPU" = "gpu" ]
then
    echo "use gpu image"
    HTTP_PORT=8890
    CONTAINER_NAME="condad-gpu"
    IMAGE="allenyllee/condad-gpu:latest" # gpu support image
    SSH_PORT=67 # gpu ssh port
else
    echo "use cpu image"
    HTTP_PORT=8889
    CONTAINER_NAME="condad"
    IMAGE="allenyllee/condad:latest"  #default image (cpu only)
    SSH_PORT=66 # default ssh port
fi


##############################
# run GUI app in docker with Xauthority file (without using xhost +local:root)
# https://stackoverflow.com/a/25280523/1851492
#
# docker/Tutorials/GUI - ROS Wiki
# http://wiki.ros.org/docker/Tutorials/GUI
#
# you need to mount volume /tmp/.docker.xauth and
# set environment vaiable XAUTHORITY=/tmp/.docker.xauth
# in your docker run command
#
# --volume=/tmp/.docker.xauth:/tmp/.docker.xauth:rw
# --env="XAUTHORITY=/tmp/.docker.xauth"
###############################

# set .docker.xauth after login, becasue /tmp will be deleted everytime system startup
# filesystem - How is the /tmp directory cleaned up? - Ask Ubuntu
# https://askubuntu.com/questions/20783/how-is-the-tmp-directory-cleaned-up
#

# workflow:
#       1. To avoid docker automatically create a $XAUTH_DIR directory before it mount,
#           insert a command which is to create $XAUTH_DIR directory
#           with mod 777 (read/write for all user) into /etc/rc.local.
#           Because /etc/rc.local will execute at the end of runlevel which before docker service start,
#           this is a good point to place it.
#       2. After docker daemon start, it will mount $XAUTH_DIR if needed.
#       3. After system login, it will execute ~/.profile to setup $XAUTH_DIR/.xauth file

XSOCK=/tmp/.X11-unix
XAUTH_DIR=/tmp/.docker.xauth
XAUTH=$XAUTH_DIR/.xauth

# 1. Use tr to swap the newline character to NUL character.
#       NUL (\000 or \x00) is nice because it doesn't need UTF-8 support and it's not likely to be used.
# 2. Use sed to match the string
# 3. Use tr to swap back.
# 4. insert a string into /etc/rc.local before exit 0
tr '\n' '\000' < /etc/rc.local | sudo tee /etc/rc.local >/dev/null
sudo sed -i 's|\x00XAUTH_DIR=.*\x00\x00|\x00|' /etc/rc.local >/dev/null
tr '\000' '\n' < /etc/rc.local | sudo tee /etc/rc.local >/dev/null
sudo sed -i 's|^exit 0.*$|XAUTH_DIR=/tmp/.docker.xauth; rm -rf $XAUTH_DIR; install -m 777 -d $XAUTH_DIR\n\nexit 0|' /etc/rc.local

# create a folder with mod 777 that can allow all other user read/write
XAUTH_DIR=/tmp/.docker.xauth; sudo rm -rf $XAUTH_DIR; install -m 777 -d $XAUTH_DIR

# append string in ~/.profile
tr '\n' '\000' < ~/.profile | sudo tee ~/.profile >/dev/null
sed -i 's|\x00XAUTH_DIR=.*-\x00|\x00|' ~/.profile
tr '\000' '\n' < ~/.profile | sudo tee ~/.profile >/dev/null
echo "XAUTH_DIR=/tmp/.docker.xauth; XAUTH=\$XAUTH_DIR/.xauth; touch \$XAUTH; xauth nlist \$DISPLAY | sed -e 's/^..../ffff/' | xauth -f \$XAUTH nmerge -" >> ~/.profile
source ~/.profile

# remove previous container
nvidia-docker stop $CONTAINER_NAME && \
nvidia-docker rm $CONTAINER_NAME

# pull latest image
nvidia-docker pull $IMAGE

# run new container
nvidia-docker run -ti -d \
    --name $CONTAINER_NAME \
    --publish $HTTP_PORT:8888 \
    --publish $SSH_PORT:22 \
    --env DISPLAY=$DISPLAY \
    --env XAUTHORITY=$XAUTH \
    --env PASSWORD=$PSWD \
    --volume $XSOCK:$XSOCK \
    --volume $XAUTH_DIR:$XAUTH_DIR \
    --volume $NOTEBOOK_DIR:/opt/notebooks \
    `#--device /dev/video0:/dev/video0 # for webcam` \
    --restart always \
    $IMAGE
