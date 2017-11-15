# anaconda with dlib
#
# VERSION               0.0.1

FROM      continuumio/anaconda3 
LABEL     maintainer="allen7575@gmail.com"

############
# update package list
############
RUN apt update

###########
# instal dlib
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
cd / && rm -rf /root/project"


###########
# install opencv
###########
RUN conda install -c conda-forge -y opencv


##############
# install ssh
##############
RUN apt install -y ssh

# enable ssh root login
RUN sed -i "s/PermitRootLogin/# PermitRootLogin/g" /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# change password to username:password
RUN echo root:root | chpasswd

# first start to preserve all SSH host keys
RUN service ssh start

# set $DISPLAY env variable for ssh login session
RUN echo 'export DISPLAY=:0' >> /etc/profile.d/ssh.sh

###################
# install VirtualGL
###################
# nvidia-virtualgl/Dockerfile at master · plumbee/nvidia-virtualgl 
# https://github.com/plumbee/nvidia-virtualgl/blob/master/Dockerfile

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
RUN apt autoremove && \
    apt clean && \
    rm /var/lib/apt/lists/*

#################
# init script
#################
ADD ./init_jupyter/* /init_jupyter/

# starting container process caused "exec: \"./extra/service_startup.sh\": permission denied" · Issue #431 · facebook/fbctf 
# https://github.com/facebook/fbctf/issues/431
RUN chmod +x /init_jupyter/*

ENTRYPOINT ["/init_jupyter/jupyter_init.sh"]

CMD ["bash"]