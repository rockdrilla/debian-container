ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BASE_IMAGE=${DISTRO}:${SUITE}
ARG BUILDD_IMAGE=${DISTRO}-buildd:${SUITE}

FROM ${IMAGE_PATH}/${BASE_IMAGE} as buildd
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install apt-utils build-essential debhelper eatmydata fakeroot ; \
    cleanup

FROM ${IMAGE_PATH}/${BUILDD_IMAGE} as buildd-helper
SHELL [ "/bin/sh", "-ec" ]

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN dpkg-divert --divert /usr/bin/py3compile.real --rename /usr/bin/py3compile ; \
    ln -s /bin/true /usr/bin/py3compile ; \
    #
    apt-install ca-certificates curl devscripts gawk git gnupg jq liblz4-tool lintian mount openssh-client openssh-client-ssh1 rsync uidmap unzip wget zip zstd ; \
    #
    python-remove-cache / ; \
    cleanup
