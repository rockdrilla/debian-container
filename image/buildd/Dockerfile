ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
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
    apt-install curl devscripts gnupg lintian mount uidmap wget ; \
    #
    python-remove-cache / ; \
    cleanup
