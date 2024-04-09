# ./Dockerfile

FROM rockylinux:8.5

# Arguments
ARG TARGETPLATFORM=linux/amd64
ARG RUNNER_VERSION=2.314.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.0

# Shell setup
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The UID env var should be used in child Containerfile.
ENV UID=1000
ENV GID=0
ENV USERNAME="runner"
ENV DEBIAN_FRONTEND=noninteractive

# This is to mimic the OpenShift behaviour of adding the dynamic user to group 0.
RUN useradd -G 0 $USERNAME
ENV HOME /home/${USERNAME}

# Make and set the working directory
RUN mkdir -p /actions-runner \
    && chown -R $USERNAME:$GID /actions-runner
WORKDIR /actions-runner

# Runner download supports amd64 as x64
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ]; then export ARCH=x64 ; fi \
    && curl -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && yum clean all

RUN yum -y install zip unzip

# Install container hooks
RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

# Runner user
RUN adduser --comment "" --uid 1000 runner \
  && usermod -aG sudo runner \
  && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# Host dependencies 
RUN yum -y upgrade && yum -y install \
    bc \
    bzip2 \
    cpio \
    dbus-x11 \
    diffutils \
    epel-release \
    expat-devel \
    git \
    glibc-devel \
    glibc-langpack-en \
    gnutls-devel \
    gmp-devel \
    libffi-devel \
    libmpc-devel \
    libjpeg-turbo-devel \
    libuuid-devel \
    ncurses-compat-libs \
    openssl-devel \
    patch \
    python3-devel \
    python3-setuptools \ 
    readline-devel \
    unzip \ 
    xorg-x11-server-Xvfb \
    xorg-x11-utils \
    xz \
    zlib-devel


RUN yum -y group install "Development Tools"

# Get fakeroot which needs epel-release 
RUN yum -y install fakeroot

# Copy in scripts and dls rootfs, annotypes, pymalcolm, and malcolmjs
COPY PandABlocks-rootfs/.github/scripts /scripts
COPY rootfs /rootfs
COPY annotypes /annotypes
COPY pymalcolm /pymalcolm
COPY malcolmjs /malcolmjs

# Toolchains and tar files
RUN bash ../scripts/GNU-toolchain.sh
RUN bash ../scripts/tar-files.sh

# For the documentation
RUN pip3 install matplotlib \ 
    rst2pdf \
    sphinx \
    sphinx-rtd-theme \
    --upgrade docutils==0.16

# Create config file for dls-rootfs
RUN bash ../scripts/config-file-rootfs.sh

# Error can't find python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Make sure git doesn't fail when used to obtain a tag name
RUN git config --global --add safe.directory '*'

# Entrypoint into the container
WORKDIR /repos
CMD ["/bin/bash"]
