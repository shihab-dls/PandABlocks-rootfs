# ./Dockerfile

FROM summerwind/actions-runner:latest

USER root

RUN apt install build-essential
