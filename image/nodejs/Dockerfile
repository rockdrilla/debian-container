ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG NODEJS_VERSION

ARG BUILD_HELPER_IMAGE=${DISTRO}-buildd-helper:${SUITE}
ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG NODEJS_MIN_IMAGE=nodejs-min:${NODEJS_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${BUILD_HELPER_IMAGE} as build-dsc
SHELL [ "/bin/sh", "-ec" ]

# this directory should be mounted as RW volume
ARG _SRC_DIR

ARG DISTRO
ARG SUITE

ARG NODEJS_VERSION
ARG NODEJS_MAJOR_VERSION

ARG DEB_BUILD_OPTIONS
ARG DEB_BUILD_PROFILES

COPY /package/.template/                       /tmp/debian/
COPY /package/nodejs/template/                 /tmp/debian/
COPY /package/nodejs/${NODEJS_MAJOR_VERSION}/  /tmp/debian/

# "/ciep.env" ensures that container limits and env are taken in account
RUN set -a ; eval $(/ciep.env) ; set +a ; \
    apt-update ; \
    deb-src-export ${_SRC_DIR} /tmp/debian ; \
    cleanup ; \
    # linkage with "build-pkg" layer
    touch /tmp/dsc

# ---

FROM ${IMAGE_PATH}/${BUILD_IMAGE} as build-pkg
SHELL [ "/bin/sh", "-ec" ]

# linkage with "build-dsc" layer
COPY --from=build-dsc /tmp/dsc /tmp/

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
ARG DEB_BUILD_PROFILES

# CI/manual execution handler
ENV BUILDINFO_MASK="container-nodejs-${NODEJS_MAJOR_VERSION}_${NODEJS_VERSION}-*_*.buildinfo"
RUN [ -z "${CI}" ] || exit 0; \
    if find ${_PKG_DIR}/ -maxdepth 1 -name "${BUILDINFO_MASK}" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
      # implicitly deletes /tmp/dsc
      cleanup ; \
      exit 0 ; \
    fi

RUN [ -e /tmp/dsc ] || exit 0 ; \
    # "/ciep.env" ensures that container limits and env are taken in account
    set -a ; eval $(/ciep.env) ; set +a ; \
    apt-update ; \
    build_start=$(date -R) ; \
    set +e ; \
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

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal-ci
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-nodejs-${NODEJS_MAJOR_VERSION} ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    node --version

CMD [ "node" ]

# ---

FROM ${IMAGE_PATH}/${NODEJS_MIN_IMAGE} as regular-ci
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
