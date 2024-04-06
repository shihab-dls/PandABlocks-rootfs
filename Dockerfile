FROM summerwind/actions-runner:latest

USER root

RUN pip install -U Jinja2
RUN apt-get install build-essential
RUN apt -y install fuse

USER runner
