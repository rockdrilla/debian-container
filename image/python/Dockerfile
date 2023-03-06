ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG PYTHON_MIN_IMAGE

# ---

FROM ${IMAGE_PATH}/${BUILD_IMAGE} as build
SHELL [ "/bin/sh", "-ec" ]

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
ARG _PKG_DIR

ARG DISTRO
ARG SUITE

ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

ARG DEB_BUILD_OPTIONS

# build context should be set to /package/python/
COPY /shim/ /tmp/debian/

RUN mkdir -p ${_SRC_DIR} ; \
    deb-src-export ${_SRC_DIR} /tmp/debian ; \
    mkdir -p ${_PKG_DIR} ; \
    set +e ; \
    # "/ciep.sh env" ensures that container limits are taken in account
    /ciep.sh env \
      deb-src-build ${_SRC_DIR}/container-shim-python-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    cleanup ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# build context should be set to /package/python/
COPY /${PYTHON_BASE_VERSION}/ /tmp/debian/

RUN if find ${_PKG_DIR}/ -maxdepth 1 -name "container-python-*_${PYTHON_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
      cleanup ; \
      exit 0 ; \
    fi ; \
    build_start=$(date -R) ; \
    apt-update ; \
    mkdir -p ${_SRC_DIR} ; \
    deb-src-export ${_SRC_DIR} /tmp/debian ; \
    mkdir -p ${_PKG_DIR} ; \
    set +e ; \
    # "/ciep.sh env" ensures that container limits are taken in account
    /ciep.sh env \
      deb-src-build ${_SRC_DIR}/container-python-*.dsc ${_PKG_DIR} ; \
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
  "container-python-${PYTHON_BASE_VERSION}_*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}_*.deb", \
  "container-shim-unqual-python-${PYTHON_BASE_VERSION}_*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

CMD [ "python3" ]

# ---

FROM ${IMAGE_PATH}/${PYTHON_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

ARG PYTHON_BASE_VERSION

COPY --from=packages [ \
  "container-python-${PYTHON_BASE_VERSION}-dev_*.deb", \
  "container-python-${PYTHON_BASE_VERSION}-full_*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}-dev_*.deb", \
  "container-shim-unqual-python-${PYTHON_BASE_VERSION}-dev_*.deb", \
  "container-shim-python-${PYTHON_BASE_VERSION}-full_*.deb", \
  "container-shim-unqual-python-${PYTHON_BASE_VERSION}-full_*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${PYTHON_BASE_VERSION}/ -name cacert.pem -type f \
#   | while read -r f ; do \
#       dpkg-divert --divert "$f.local" --rename "$f" ; \
#       rm -f "$f" ; \
#       ln -vs ${REQUESTS_CA_BUNDLE} "$f" ; \
#   done ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version ; \
    pip3 --version

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-python-${PYTHON_BASE_VERSION} ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

CMD [ "python3" ]

# ---

FROM ${IMAGE_PATH}/${PYTHON_MIN_IMAGE} as regular-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-python-${PYTHON_BASE_VERSION}-dev ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${PYTHON_BASE_VERSION}/ -name cacert.pem -type f \
#   | while read -r f ; do \
#       dpkg-divert --divert "$f.local" --rename "$f" ; \
#       rm -f "$f" ; \
#       ln -vs ${REQUESTS_CA_BUNDLE} "$f" ; \
#   done ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version ; \
    pip3 --version
