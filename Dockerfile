# Reference : https://gzupark.dev/blog/A-guide-to-make-the-reproducible-environment-using-the-Docker-for-deep-learning-researcher/
# Reference 2 : https://velog.io/@whattsup_kim/GPU-%EA%B0%9C%EB%B0%9C%ED%99%98%EA%B2%BD-%EA%B5%AC%EC%B6%95%ED%95%98%EA%B8%B0-docker%EB%A5%BC-%ED%99%9C%EC%9A%A9%ED%95%98%EC%97%AC-%EA%B0%9C%EB%B0%9C%ED%99%98%EA%B2%BD-%ED%95%9C-%EB%B2%88%EC%97%90-%EA%B5%AC%EC%B6%95%ED%95%98%EA%B8%B0
# base image. this dockerfile is written based on nvidia/cuda images.
FROM nvidia/cuda:11.6.2-cudnn8-devel-ubuntu20.04

# for package install
ENV DEBIAN_FRONTEND=noninteractive

# install basic packages
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
    ca-certificates \
    ccache \
    cmake \
    curl \
    git \
    libgl1-mesa-glx \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libzmq3-dev \
    libjpeg-dev \
    libpng-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    pkg-config \
    software-properties-common \
    ssh \
    sudo \
    unzip \
    wget
RUN rm -rf /var/lib/apt/lists/*

# add normal user and give sudo
# ARG UID=1000
# ARG USER_NAME=gongms

# RUN adduser $USER_NAME -u $UID --quiet --gecos "" --disabled-password && \
#     echo "$USER_NAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME && \
#     chmod 0440 /etc/sudoers.d/$USER_NAME

# ENV HOME /home/$USER_NAME
# RUN mkdir $HOME/.cache $HOME/.config && \
#     chmod -R 777 $HOME 
	
# RUN mkdir $HOME/workspace
# WORKDIR $HOME/workspace

# install miniconda
ENV LANG C.UTF-8
RUN curl -o /tmp/miniconda.sh -sSL http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -bfp /usr/local && \
    rm /tmp/miniconda.sh
RUN conda update -y conda

# switch to normal user before creating conda environment
# USER $USER_NAME
# SHELL ["/bin/bash", "-c"]

# make conda environment
ARG PYTHON_VERSION=3.10
ARG CONDA_ENV_NAME=main

# RUN conda create -n $CONDA_ENV_NAME
# RUN conda create -n $CONDA_ENV_NAME --file package-list.txt
# RUN conda env create -f environment.yaml
RUN conda create -n $CONDA_ENV_NAME python=$PYTHON_VERSION
ENV PATH /usr/local/envs/$CONDA_ENV_NAME/bin:$PATH
RUN echo "source activate ${CONDA_ENV_NAME}" >> ~/.bashrc


WORKDIR /workspace

# python package install via pip. be careful with current working directory
# COPY requirements.txt requirements.txt

SHELL ["/bin/bash", "-c"]
RUN source activate ${CONDA_ENV_NAME} && \
	conda install -y pip && \
    conda install -y pytorch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 cudatoolkit=11.6 -c pytorch -c conda-forge
#	python -m pip install --no-cache-dir -r requirements.txt
