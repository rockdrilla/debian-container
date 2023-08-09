ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG PYTHON_VERSION

ARG BUILD_HELPER_IMAGE=${DISTRO}-buildd-helper:${SUITE}
ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG PYTHON_MIN_IMAGE=python-min:${PYTHON_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${BUILD_HELPER_IMAGE} as build-shim
SHELL [ "/bin/sh", "-ec" ]

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
ARG _PKG_DIR

ARG DISTRO
ARG SUITE

ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

COPY /package/.template/    /tmp/debian/
COPY /package/python/shim/  /tmp/debian/

# "/ciep.env" ensures that container limits and env are taken in account
RUN set -a ; eval $(/ciep.env) ; set +a ; \
    build_start=$(date -R) ; \
    apt-update ; \
    deb-src-export ${_SRC_DIR} /tmp/debian ; \
    set +e ; \
    deb-src-build ${_SRC_DIR}/container-shim-python-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    build_finish=$(date -R) ; \
    cleanup ; \
    echo "# build started at:  ${build_start}" ; \
    echo "# build finished at: ${build_finish}" ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM ${IMAGE_PATH}/${BUILD_HELPER_IMAGE} as build-dsc
SHELL [ "/bin/sh", "-ec" ]

# this directory should be mounted as RW volume
ARG _SRC_DIR

ARG DISTRO
ARG SUITE

ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

ARG DEB_BUILD_OPTIONS
ARG DEB_BUILD_PROFILES

COPY /package/.template/                      /tmp/debian/
COPY /package/python/template/                /tmp/debian/
COPY /package/python/${PYTHON_BASE_VERSION}/  /tmp/debian/

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

ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

ARG DEB_BUILD_OPTIONS
ARG DEB_BUILD_PROFILES

# CI/manual execution handler
ENV BUILDINFO_MASK="container-python-${PYTHON_BASE_VERSION}_${PYTHON_VERSION}-*_*.buildinfo"
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
    deb-src-build ${_SRC_DIR}/container-python-${PYTHON_BASE_VERSION}_${PYTHON_VERSION}-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    build_finish=$(date -R) ; \
    cleanup ; \
    echo "# build started at:  ${build_start}" ; \
    echo "# build finished at: ${build_finish}" ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as python-layout
SHELL [ "/bin/sh", "-ec" ]

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

CMD [ "python3" ]

# ---

FROM python-layout as minimal
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "container-python-${PYTHON_BASE_VERSION}_${PYTHON_VERSION}-*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}_*.deb", \
  "/tmp/" ]

RUN apt-install /tmp/*.deb ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

# ---

FROM ${IMAGE_PATH}/${PYTHON_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "container-python-${PYTHON_BASE_VERSION}-dev_${PYTHON_VERSION}-*.deb", \
  "container-python-${PYTHON_BASE_VERSION}-full_${PYTHON_VERSION}-*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}-dev_*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}-full_*.deb", \
  "/tmp/" ]

RUN apt-install /tmp/*.deb ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version ; \
    pip3 --version

# ---

FROM python-layout as minimal-ci
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-python-${PYTHON_BASE_VERSION} ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

CMD [ "python3" ]

# ---

FROM ${IMAGE_PATH}/${PYTHON_MIN_IMAGE} as regular-ci
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-python-${PYTHON_BASE_VERSION}-dev ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version ; \
    pip3 --version
