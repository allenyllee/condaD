# anaconda with dlib
#
# VERSION               0.0.1

FROM      continuumio/anaconda3
LABEL     maintainer="allen7575@gmail.com"

############
# update package list
############
RUN apt update

##############################
#########################
## Tools
#########################
##############################

##########
# install vim
##########
RUN apt install -y vim

##############################
#########################
## Libraries
#########################
##############################

###########
# install dlib
###########

# Install Dlib on Ubuntu | Learn OpenCV
# https://www.learnopencv.com/install-dlib-on-ubuntu/
#
# dependencies for build dlib: cmake, boost, PkgConfig
# build-essential: gcc,g++,make...
# check dependency: apt-cache depends build-essential
RUN apt install -y build-essential cmake libboost-python-dev pkg-config

# dependencies for X11 GUI window
RUN apt install -y libx11-dev

# dependencies for ??
RUN apt install -y libatlas-base-dev libgtk-3-dev

# build dlib
# davisking/dlib: A toolkit for making real world machine learning and data analysis applications in C++
# https://github.com/davisking/dlib
RUN bash -c " \
mkdir -p /root/project && \
cd /root/project && \
git clone https://github.com/davisking/dlib.git && \
cd dlib/ && \
python setup.py install && \
`# python setup.py install --yes USE_AVX_INSTRUCTIONS &&` \
`# python setup.py install --yes DLIB_USE_CUDA` \
cd / && rm -rf /root/project"


###########
# install opencv
###########
RUN conda install -c conda-forge -y opencv


##############################
#########################
## ssh daemon
#########################
##############################

##############
# install ssh
##############
RUN apt install -y ssh

# enable ssh root login
# 技术|Linux有问必答：如何修复“X11 forwarding request failed on channel 0”错误
# https://linux.cn/article-4014-1.html
RUN sed -i "s/PermitRootLogin/# PermitRootLogin/g" /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    sed -i "s/X11UseLocalhost/# X11UseLocalhost/g" /etc/ssh/sshd_config && \
    echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

# change root password
RUN echo root:root | chpasswd

# add guest user
# useradd - Ubuntu 14.04: New user created from command line has missing features - Ask Ubuntu
# https://askubuntu.com/questions/643411/ubuntu-14-04-new-user-created-from-command-line-has-missing-features
#
# You should run the command in the following manner:
# sudo useradd -m sam -s /bin/bash
#
#  -s, --shell SHELL
#       The name of the user's login shell.
#  -m, --create-home
#       Create the user's home directory if it does not exist.
#
# python - OpenCV Error: (-215)size.width>0 && size.height>0 in function imshow - Stack Overflow
# https://stackoverflow.com/questions/27953069/opencv-error-215size-width0-size-height0-in-function-imshow/47308803#47308803
#
RUN useradd -m guest -s /bin/bash && \
    echo guest:guest | chpasswd && \
    usermod -a -G video guest `# grant access to video device`


# first start to preserve all SSH host keys
RUN service ssh start

# set $DISPLAY env variable for ssh login session
#RUN echo 'export DISPLAY=:0' >> /etc/profile.d/ssh.sh

###############
# install sshfs
###############
RUN apt install -y sshfs

# make dir for reverse sshfs use
RUN mkdir ~/client-sshfs-project

##############################
#########################
## X11 GUI
#########################
##############################

#############
# install xeyes, xclock
#############
RUN apt install -y x11-apps

###################
# install VirtualGL
###################
# nvidia-virtualgl/Dockerfile at master · plumbee/nvidia-virtualgl
# https://github.com/plumbee/nvidia-virtualgl/blob/master/Dockerfile

#
# install glxgears
# How to Check 3D Acceleration (FPS) in Ubuntu/Linux Mint
# http://www.upubuntu.com/2013/11/how-to-check-3d-acceleration-fps-in.html
#
# use following command to check
# export LIBGL_DEBUG=verbose && glxgears
#
# How can i deal with 'libGL error: failed to load driver: swrast.' · Issue #509 · openai/gym
# https://github.com/openai/gym/issues/509
#
# Based on the dockerfile of nvidia/cuda, I can solve this problem.
# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/8.0/runtime/Dockerfile
#
# Or you can just use it with nvidia-docker to create another container run all the stuff without touching your OS environments.
#
# install mesa-utils for testing glxgear
RUN apt install -y mesa-utils

# install curl for download VirtualGL
RUN apt install -y curl

# download & install VirtualGL
ENV VIRTUALGL_VERSION 2.5.2
RUN curl -sSL https://downloads.sourceforge.net/project/virtualgl/"${VIRTUALGL_VERSION}"/virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb -o virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb && \
    dpkg -i virtualgl_*_amd64.deb && \
    rm virtualgl_*_amd64.deb

# install libxv1 to avoid
# glxgears: error while loading shared libraries: libXv.so.1: cannot open shared object file: No such file or directory
# when executed vglrun glxgears
RUN apt install -y libxv1

# Granting Access to the 3D X Server
# https://cdn.rawgit.com/VirtualGL/virtualgl/2.5.2/doc/index.html#hd006001
#RUN /opt/VirtualGL/bin/vglserver_config -config +s +f -t


##############################
#########################
## nvidia-docker
#########################
##############################

####################
# nvidia-docker links
####################
# Image inspection · NVIDIA/nvidia-docker Wiki
# https://github.com/NVIDIA/nvidia-docker/wiki/Image-inspection#nvidia-docker
# when nvidia-docker run is used, we inspect the image specified on the command-line. In this image,
# we lookup the presence and the value of the label com.nvidia.volumes.needed

# if you are using nvidia driver, you need to add this to avoid
# libGL error: failed to load driver: swrast
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

# set PATH & LD_LIBRARY_PATH env variable for ssh login session
# Env variable cannot be passed to container - General Discussions - Docker Forums
# https://forums.docker.com/t/env-variable-cannot-be-passed-to-container/5298/6
RUN echo 'export PATH=/usr/local/nvidia/bin:$PATH' >> /etc/profile.d/nvidia.sh && \
    echo 'export LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH' >> /etc/profile.d/nvidia.sh

##############
# upgrade
##############
RUN apt upgrade -y

##############
# cleanup
##############
# debian - clear apt-get list - Unix & Linux Stack Exchange
# https://unix.stackexchange.com/questions/217369/clear-apt-get-list
#
# bash - autoremove option doesn't work with apt alias - Ask Ubuntu
# https://askubuntu.com/questions/573624/autoremove-option-doesnt-work-with-apt-alias
#
RUN apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#################
# init script
#################
ADD ./init_jupyter/* /init_jupyter/

# starting container process caused "exec: \"./extra/service_startup.sh\": permission denied" · Issue #431 · facebook/fbctf
# https://github.com/facebook/fbctf/issues/431
RUN chmod +x /init_jupyter/*

ENTRYPOINT ["/init_jupyter/jupyter_init.sh"]

CMD ["bash"]