FROM allenyllee/anaconda3-fix

#
# tensorflow/Dockerfile.gpu at master · tensorflow/tensorflow
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.gpu
# 

LABEL maintainer="Craig Citro <craigcitro@google.com>"

# # Pick up some TF dependencies
# RUN apt-get update && apt-get install -y --no-install-recommends \
#         build-essential \
#         cuda-command-line-tools-9-0 \
#         cuda-cublas-9-0 \
#         cuda-cufft-9-0 \
#         cuda-curand-9-0 \
#         cuda-cusolver-9-0 \
#         cuda-cusparse-9-0 \
#         curl \
#         libcudnn7=7.1.4.18-1+cuda9.0 \
#         libnccl2=2.2.13-1+cuda9.0 \
#         libfreetype6-dev \
#         libhdf5-serial-dev \
#         libpng12-dev \
#         libzmq3-dev \
#         pkg-config \
#         python \
#         python-dev \
#         python3-pip \
#         python3-dev \
#         python-virtualenv \
#         rsync \
#         software-properties-common \
#         unzip \
#         && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

RUN ln -s -f /usr/bin/python3 /usr/bin/python

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip -V && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        scipy \
        sklearn \
        && \
    python -m ipykernel.kernelspec

# --- DO NOT EDIT OR DELETE BETWEEN THE LINES --- #
# These lines will be edited automatically by parameterized_docker_build.sh. #
# COPY _PIP_FILE_ /
# RUN pip --no-cache-dir install /_PIP_FILE_
# RUN rm -f /_PIP_FILE_


# Install TensorFlow GPU version.
RUN pip --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.10.0-cp36-cp36m-linux_x86_64.whl
# --- ~ DO NOT EDIT OR DELETE BETWEEN THE LINES --- #




# Set up our notebook config.
#COPY jupyter_notebook_config.py /root/.jupyter/

# Copy sample notebooks.
#COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
#COPY run_jupyter.sh /

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

#WORKDIR "/notebooks"

#CMD ["/run_jupyter.sh", "--allow-root"]
