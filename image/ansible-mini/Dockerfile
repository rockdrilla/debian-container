ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG PYTHON_VERSION=3.11
ARG BASE_IMAGE=python:${PYTHON_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install \
      ca-certificates \
      cowsay \
      curl \
      git \
      openssh-client \
      openssh-client-ssh1 \
      patch \
      sshpass \
    ; \
    cleanup

COPY /ansible-filter.xglob.txt /etc/container/cleanup/python-site-packages

RUN apt-wrap-python \
      pip install \
        "ansible~=${ANSIBLE_VERSION}.0" \
        ansible-lint \
        netaddr \
    ; \
    python-site-cleanup ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    ansible --version

ENV PAGER=cat

RUN ANSIBLE_HOME='/ansible' ; ANSIBLE_UID='30000' ; \
    add-simple-user ansible ${ANSIBLE_UID} "${ANSIBLE_HOME}" ; \
    install -d -o ansible -g ansible -m 0750 "${ANSIBLE_HOME}" ; \
    # compat symlinks
    ln -s "${ANSIBLE_HOME}" /home/ansible ; \
    ln -s "${ANSIBLE_HOME}" /etc/ansible ; \
    # preseed "home"
    cd "${ANSIBLE_HOME}" ; \
    install -d -o ansible -g ansible -m 0700 .cache .config .gnupg .local .ssh

RUN install -d -m 01777 /work
WORKDIR /work
VOLUME /work

CMD [ "bash" ]
