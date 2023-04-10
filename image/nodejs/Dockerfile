ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG NODEJS_MIN_IMAGE

# ---

FROM ${IMAGE_PATH}/${BUILD_IMAGE} as build
SHELL [ "/bin/sh", "-ec" ]

ARG CI

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
ARG _PKG_DIR

ARG DISTRO
ARG SUITE

ARG NODEJS_VERSION
ARG NODEJS_MAJOR_VERSION

ARG DEB_BUILD_OPTIONS

# build context should be set to /package/nodejs/
COPY /template/ /tmp/debian/
COPY /${NODEJS_MAJOR_VERSION}/ /tmp/debian/

RUN if [ -z "${CI}" ] ; then \
      if find ${_PKG_DIR}/ -maxdepth 1 -name "container-nodejs-${NODEJS_MAJOR_VERSION}_${NODEJS_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
        cleanup ; \
        exit 0 ; \
      fi ; \
    fi ; \
    build_start=$(date -R) ; \
    apt-update ; \
    deb-src-export ${_SRC_DIR} /tmp/debian ; \
    set +e ; \
    # "/ciep.sh env" ensures that container limits are taken in account
    /ciep.sh env \
      deb-src-build ${_SRC_DIR}/container-nodejs-${NODEJS_MAJOR_VERSION}_${NODEJS_VERSION}-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    build_finish=$(date -R) ; \
    cleanup ; \
    echo "# build started at:  ${build_start}" ; \
    echo "# build finished at: ${build_finish}" ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "container-nodejs-${NODEJS_MAJOR_VERSION}_${NODEJS_VERSION}-*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    node --version

CMD [ "node" ]

# ---

FROM ${IMAGE_PATH}/${NODEJS_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

ARG NODEJS_MAJOR_VERSION

COPY --from=packages [ \
  "container-nodejs-${NODEJS_MAJOR_VERSION}-dev_${NODEJS_VERSION}-*.deb", \
  "container-nodejs-${NODEJS_MAJOR_VERSION}-full_${NODEJS_VERSION}-*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    node --version ; \
    npm --version ; \
    yarn --version ; \
    # cleanup after yarn (sic!) 
    cleanup

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-nodejs-${NODEJS_MAJOR_VERSION} ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    node --version

CMD [ "node" ]

# ---

FROM ${IMAGE_PATH}/${NODEJS_MIN_IMAGE} as regular-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-nodejs-${NODEJS_MAJOR_VERSION}-dev ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    node --version ; \
    npm --version ; \
    yarn --version ; \
    # cleanup after yarn (sic!) 
    cleanup
