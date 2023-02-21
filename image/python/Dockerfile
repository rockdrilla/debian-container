ARG IMAGE_REGISTRY=docker.io
ARG IMAGE_DIRECTORY=rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG PYTHON_MIN_IMAGE

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BUILD_IMAGE} as build
SHELL [ "/bin/sh", "-ec" ]

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
# ARG _PKG_DIR=/usr/local/lib
ARG _PKG_DIR

ARG DISTRO
ARG SUITE
ARG PYTHON_BASE_VERSION

COPY /${PYTHON_BASE_VERSION}/ /tmp/debian/

ARG DEB_SRC_BUILD_PURGE
ARG DEB_BUILD_OPTIONS

RUN if ! find ${_PKG_DIR}/ -maxdepth 1 -name "*_${PYTHON_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
        build_start=$(date -R) ; \
        apt-update ; \
        mkdir -p ${_SRC_DIR} ; \
        deb-src-export ${_SRC_DIR} /tmp/debian ; \
        mkdir -p ${_PKG_DIR} ; \
        set +e ; \
        # "/ciep.sh env" ensures that container limits are taken in account
        /ciep.sh env \
          deb-src-build ${_SRC_DIR}/*.dsc ${_PKG_DIR} ; \
        result=$? ; \
        set -e ; \
        build_finish=$(date -R) ; \
        cleanup ; \
        echo "# build started at:  ${build_start}" ; \
        echo "# build finished at: ${build_finish}" ; \
        echo "# build return code: ${result}" ; \
        [ "${result}" = 0 ] || exit ${result} ; \
    fi ; \
    # linkage with final layer
    cp ${_PKG_DIR}/*_${PYTHON_VERSION}-*_*.buildinfo /tmp/

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as minimal
SHELL [ "/bin/sh", "-ec" ]

# linkage with build layer
COPY --from=build  /tmp/*.buildinfo  /tmp/

# this directory should be mounted as volume
# ARG _PKG_DIR=/usr/local/lib

RUN arch=$(dpkg --print-architecture) ; \
    pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    find /usr/local/lib/ -regextype egrep -regex ".+/container-python-${pybasever}_.+_(all|${arch})\\.deb\$" -type f \
      -exec dpkg -i '{}' '+' \
    || apt-install --fix-broken ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${pybasever}/ -name cacert.pem -type f \
#   | while read -r f ; do \
#       dpkg-divert --divert "$f.local" --rename "$f" ; \
#       rm -f "$f" ; \
#       ln -vs ${REQUESTS_CA_BUNDLE} "$f" ; \
#   done ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

CMD [ "python3" ]

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${PYTHON_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

# this directory should be mounted as volume
# ARG _PKG_DIR=/usr/local/lib

RUN arch=$(dpkg --print-architecture) ; \
    pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    find /usr/local/lib/ -regextype egrep -regex ".+/container-python-${pybasever}(-dev|-full)_.+_(all|${arch})\\.deb\$" -type f \
      -exec dpkg -i '{}' '+' \
    || apt-install --fix-broken ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${pybasever}/ -name cacert.pem -type f \
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

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as minimal-apt
SHELL [ "/bin/sh", "-ec" ]

RUN pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    apt-install container-python-${pybasever} ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${pybasever}/ -name cacert.pem -type f \
#   | while read -r f ; do \
#       dpkg-divert --divert "$f.local" --rename "$f" ; \
#       rm -f "$f" ; \
#       ln -vs ${REQUESTS_CA_BUNDLE} "$f" ; \
#   done ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

CMD [ "python3" ]

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${PYTHON_MIN_IMAGE} as regular-apt
SHELL [ "/bin/sh", "-ec" ]

RUN pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    apt-install container-python-${pybasever}-full ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${pybasever}/ -name cacert.pem -type f \
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
