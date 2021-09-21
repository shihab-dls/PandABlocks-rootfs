# A devcontainer for PandABlocks-rootfs

FROM ubuntu:20.04 AS environment

ARG PLATFORM="zynq"

# standard devcontainer tools and libraries
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    busybox \
    git \
    python3-pip \
    python3.9-minimal \
    vim \
    && rm -rf /var/lib/apt/lists/*

# useful devcontainer utilities
RUN busybox --install

# python dependencies
RUN pip install rst2pdf

ENV GITHUB_WORKSPACE=/tools
WORKDIR /tools

# get the Arm GNU toolchain and tar files
COPY /.github/scripts scripts
RUN bash scripts/GNU-toolchain.sh ${PLATFORM}
RUN bash scripts/tar-files.sh

# prepare CONFIG files for pandablocks-rootfs and rootfs itself
RUN mkdir rootfs \
    mkdir PandABlocks-rootfs && \
    bash scripts/config-file-pbrootfs.sh ${PLATFORM} && \
    bash scripts/config-file-rootfs.sh

# tool chain dependecies
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    bison \
    expat \
    fakeroot \
    flex \
    libffi-dev \
    libssl-dev \
    libncurses5-dev \
    libreadline-dev \
    zlib1g-dev

COPY /.devbuild.sh /tools/devbuild.sh

# Python/Sphinx requirements
RUN pip install pipenv

