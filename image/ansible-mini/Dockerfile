ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG PYTHON_VERSION=3.11
ARG BASE_IMAGE=python:${PYTHON_VERSION}-${SUITE}
ARG STAGE_IMAGE=python-dev:${PYTHON_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${STAGE_IMAGE} as stage
SHELL [ "/bin/sh", "-ec" ]

COPY /ansible-filter.xglob.txt /etc/k2/cleanup/python-site-packages

RUN apt-wrap-python \
      pip install \
        "ansible~=${ANSIBLE_VERSION}.0" \
        ansible-lint \
        netaddr \
    ; \
    ## list packages
    echo ; \
    pip list --format freeze ; \
    echo ; \
    ## Python site-packages cleanup
    python-site-cleanup ; \
    ## adjust certifi
    find ${SITE_PACKAGES}/ -name cacert.pem -type f \
    | while read -r f ; do \
        [ -n "$f" ] || continue ; \
        rm -f "$f" ; \
        ln -fvs /etc/ssl/certs/ca-certificates.crt "$f" ; \
    done ; \
    ## strip debug info
    quiet apt-install binutils ; \
    ufind -z /usr/local ${SITE_PACKAGES} | xvp is-elf -z - | sort -zV > /tmp/elves ; \
    xvp ls -lS /tmp/elves ; \
    xvp strip --strip-debug /tmp/elves ; echo ; \
    xvp ls -lS /tmp/elves ; \
    cleanup

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE}
SHELL [ "/bin/sh", "-ec" ]

COPY --from=stage  ${SITE_PACKAGES}/  ${SITE_PACKAGES}/
COPY --from=stage  /usr/local/        /usr/local/

RUN apt-install \
      ca-certificates \
      cowsay \
      curl \
      git \
      openssh-client \
      openssh-client-ssh1 \
      patch \
      rsync \
      sshpass \
    ; \
    cleanup

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

# smoke/qa
RUN set -xv ; \
    ansible --version
