ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG PYTHON_VERSION=3.11.3
ARG BASE_IMAGE=python:${PYTHON_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

COPY /ansible-filter.xglob.txt /etc/container/cleanup/python-site-packages

RUN CONTAINER_PYTHON_GLOBALBIN=1 \
    apt-wrap-python pip install "ansible~=${ANSIBLE_VERSION}.0" ; \
    python-site-cleanup ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    ansible --version

RUN _uid='30000' ; _home='/ansible' ; \
    echo "ansible:x:${_uid}:" >> /etc/group ; \
    echo "ansible:!:::::::" >> /etc/shadow ; \
    echo "ansible:x:${_uid}:${_uid}:ansible:${_home}:/bin/false" >> /etc/passwd ; \
    install -d -o ansible -g ansible -m 0750 "${_home}" ; \
    ln -s "${_home}" /home/ansible ; \
    cd "${_home}" ; \
    install -d -o ansible -g ansible -m 0700 .cache .config .gnupg .local .ssh

RUN install -d -m 01777 /work
WORKDIR /work
VOLUME /work

CMD [ "bash" ]
