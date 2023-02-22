ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BASE_IMAGE=${DISTRO}-min:${SUITE}

FROM ${IMAGE_PATH}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install build-essential debhelper eatmydata fakeroot ; \
    cleanup
