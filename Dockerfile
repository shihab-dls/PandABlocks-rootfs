FROM rockylinux:9

ARG TARGETPLATFORM=linux/amd64
ARG RUNNER_VERSION=2.314.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.0
# Docker and Docker Compose arguments
ARG CHANNEL=stable
ARG DOCKER_VERSION=24.0.7
ARG DOCKER_COMPOSE_VERSION=v2.23.0
ARG DUMB_INIT_VERSION=1.2.5

# User UID set to a standard that is allocated to initial non-root unix users, to align with possible existing user management. ARG RUNNER_UID=1000
ARG DOCKER_GID=1001

# Install necesary dependancies
ENV DEBIAN_FRONTEND=noninteractive
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
    sudo \
    unzip \ 
    xorg-x11-server-Xvfb \
    xorg-x11-utils \
    xz \
    zlib-devel

RUN yum -y group install "Development Tools"

RUN yum -y install fakeroot

COPY PandABlocks-rootfs/.github/scripts /scripts
COPY rootfs /rootfs
COPY annotypes /annotypes
COPY pymalcolm /pymalcolm
COPY malcolmjs /malcolmjs

RUN bash scripts/GNU-toolchain.sh
RUN bash scripts/tar-files.sh

# For the documentation
RUN pip3 install matplotlib \ 
    rst2pdf \
    sphinx \
    sphinx-rtd-theme \
    --upgrade docutils==0.16

RUN bash scripts/config-file-rootfs.sh

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN git config --global --add safe.directory '*'

# Add runner user to sudo group
RUN adduser --comment "" --uid $RUNNER_UID runner \
    && groupadd docker --gid $DOCKER_GID \
    && usermod -aG wheel runner \
    && usermod -aG wheel root \
    && usermod -aG docker runner \
    && echo "%wheel   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

# Set runner home directory
ENV HOME=/home/runner

# Process supervisor for child processes
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
    && curl -fLo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_${ARCH} \
    && chmod +x /usr/bin/dumb-init

# Set up ARC in docker image.
ENV RUNNER_ASSETS_DIR=/runnertmp
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm -f runner.tar.gz \
    && ./bin/installdependencies.sh

# Set up of hosted tools caching
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir /opt/hostedtoolcache \
    && chgrp docker /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache

# Set up container hooks for integration with K8S
RUN cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm -f runner-container-hooks.zip

# Ensure local installations are accessible
ENV PATH="${PATH}:${HOME}/.local/bin/"
RUN echo "PATH=${PATH}" > /etc/environment

#Switch to runner
USER runner

#Setup up entrypoint to run as bash and provides default
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]