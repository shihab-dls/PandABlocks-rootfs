# ./Dockerfile

FROM registry.access.redhat.com/ubi9/ubi-init:9.3

# Arguments
ARG TARGETPLATFORM=linux/amd64
ARG RUNNER_VERSION=2.314.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The UID env var should be used in child Containerfile.
ENV UID=1000
ENV GID=0
ENV USERNAME="runner"

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
    && dnf clean all

# Install container hooks
RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

# Runner user
RUN adduser --disabled-password --gecos "" --uid 1000 runner \
  && usermod -aG sudo runner \
  && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

RUN dnf update -y \
    && dnf install -y \
    git \
    jq \
    && dnf clean all

# Install helm using the in-line curl to bash method
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Use an install script to install the `gh` cli, more about that below!
COPY images/software/gh-cli.sh gh-cli.sh
RUN bash gh-cli.sh && rm gh-cli.sh


