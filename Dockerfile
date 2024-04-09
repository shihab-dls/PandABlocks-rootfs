# ./Dockerfile

FROM rockylinux:8.5

ARG TARGETPLATFORM
ARG RUNNER_VERSION
ARG RUNNER_CONTAINER_HOOKS_VERSION
ARG RUNNER_UID=1000
ARG DOCKER_GID=1001

ENV RUNNER_ASSETS_DIR=/runnertmp
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && mv ./externals ./externalstmp \
    # libyaml-dev is required for ruby/setup-ruby action.
    # It is installed after installdependencies.sh and before removing /var/lib/apt/lists
    # to avoid rerunning apt-update on its own.
    && apt-get install -y libyaml-dev \

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
RUN bash scripts/GNU-toolchain.sh
RUN bash scripts/tar-files.sh

# For the documentation
RUN pip3 install matplotlib \ 
    rst2pdf \
    sphinx \
    sphinx-rtd-theme \
    --upgrade docutils==0.16

# Create config file for dls-rootfs
RUN bash scripts/config-file-rootfs.sh

# Error can't find python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Make sure git doesn't fail when used to obtain a tag name
RUN git config --global --add safe.directory '*'

USER runner

# Entrypoint into the container
WORKDIR /repos
CMD ["/bin/bash"]
