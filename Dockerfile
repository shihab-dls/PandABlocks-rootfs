FROM summerwind/actions-runner:ubuntu-20.04

USER root

RUN apt update
RUN pip install -U Jinja2
RUN apt-get install build-essential
USER runner
RUN apt-get -y install fuse3

