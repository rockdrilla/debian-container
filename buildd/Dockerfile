ARG IMAGE_REGISTRY=docker.io
ARG IMAGE_DIRECTORY=rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BASE_IMAGE=${DISTRO}-min:${SUITE}

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

RUN if apt-backports status ; then \
        apt-backports enable-all ; \
    fi ; \
    apt-install debhelper build-essential ; \
    if apt-backports status ; then \
        apt-pin backports rm ; \
    fi ; \
    cleanup
