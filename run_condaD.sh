#!/bin/bash
XSOCK=/tmp/.X11-unix
XAUTH_DIR=/tmp/.docker.xauth
XAUTH=.xauth

# set .docker.xauth after login, becasue /tmp will be deleted everytime system startup
# filesystem - How is the /tmp directory cleaned up? - Ask Ubuntu 
# https://askubuntu.com/questions/20783/how-is-the-tmp-directory-cleaned-up
# 

# workflow:
#       1. To avoid docker daemon automatically create a /tmp/.docker.xauth/ directory, 
#           insert a item which is to create /temp/.docker.xauth/ directory 
#           with mod 777 (read/write for all user) into /etc/rc.local.
#           Because /etc/rc.local will execute at the end of runlevel which before docker service start, 
#           this is a good point to place it.
#       2. After docker daemon start, it will mount /tmp/.docker.xauth/ if needed. 
#       3. After login, system will execute ~/.profile to setup /tmp/.docker.xauth/.xauth file

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
echo "XAUTH_DIR=/tmp/.docker.xauth; XAUTH=.xauth; touch \$XAUTH_DIR/\$XAUTH; xauth nlist \$DISPLAY | sed -e 's/^..../ffff/' | xauth -f \$XAUTH_DIR/\$XAUTH nmerge -" >> ~/.profile
source ~/.profile


PSWD=$1
NOTEBOOK_DIR=$2

nvidia-docker run -ti \
    --name anaconda \
    --publish 8889:8888 \
    --env DISPLAY=$DISPLAY \
    --env XAUTHORITY=$XAUTH_DIR/$XAUTH \
    --env PASSWORD=$PSWD \
    --volume $XSOCK:$XSOCK \
    --volume $XAUTH_DIR:$XAUTH_DIR \
    --volume $NOTEBOOK_DIR:/opt/notebooks \
    --restart always \
    allenyllee/condad:latest
