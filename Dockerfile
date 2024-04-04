FROM summerwind/actions-runner:latest

USER root

RUN apt-get install build-essential

USER RUNNER
