ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BASE_IMAGE=${DISTRO}:${SUITE}

FROM ${IMAGE_PATH}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install apt-utils less lsof netbase ncurses-base procps psmisc tzdata vim-tiny ; \
    # install vim-tiny as variant for vim
    vim=/usr/bin/vim ; \
    update-alternatives --install ${vim} vim ${vim}.tiny 1 ; \
    # quirk for vim-tiny
    find /usr/share/vim/ -name debian.vim \
    | sed 's/debian.vim/defaults.vim/' \
    | xargs -d '\n' -r touch ; \
    #
    cleanup
