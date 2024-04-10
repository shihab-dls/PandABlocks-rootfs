# ./Dockerfile

FROM summerwind/actions-runner:ubuntu-20.04

USER root

RUN apt update
RUN pip install -U Jinja2
RUN apt-get install build-essential
COPY PandABlocks-rootfs/.github/scripts /scripts
COPY rootfs /rootfs
COPY annotypes /annotypes
COPY pymalcolm /pymalcolm
COPY malcolmjs /malcolmjs
# Toolchains and tar files
RUN bash scripts/GNU-toolchain.sh
RUN bash scripts/tar-files.sh
RUN apt install libtinfo-dev
RUN ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5

USER runner

