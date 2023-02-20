ARG IMAGE_REGISTRY=docker.io
ARG IMAGE_DIRECTORY=rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}

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
ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

# allows to preseed get-pip.py and upstream tarballs
# NB: get-pip.py isn't used and even present (for now)
COPY --from=preseed /*        /tmp
COPY /${PYTHON_BASE_VERSION}/ /tmp/debian/

ARG DEB_SRC_BUILD_PURGE
ARG DEB_BUILD_OPTIONS

RUN if ! find ${_PKG_DIR}/ -maxdepth 1 -name "*_${PYTHON_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
        build_start=$(date -R) ; \
        mkdir -p ${_SRC_DIR} ; \
        : mv /tmp/get-pip.py /tmp/debian/ ; \
        deb-src-export ${_SRC_DIR} /tmp/debian ; \
        mkdir -p ${_PKG_DIR} ; \
        set +e ; \
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

ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

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

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

# this directory should be mounted as volume
# ARG _PKG_DIR=/usr/local/lib

ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN arch=$(dpkg --print-architecture) ; \
    pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    find /usr/local/lib/ -regextype egrep -regex ".+/container-python(|-dev|-full)-${pybasever}_.+_(all|${arch})\\.deb\$" -type f \
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

CMD [ "python3" ]

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as minimal-apt
SHELL [ "/bin/sh", "-ec" ]

ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

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

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as regular-apt
SHELL [ "/bin/sh", "-ec" ]

ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN pybasever=$(echo "${PYTHON_VERSION}" | cut -d. -f1-2) ; \
    apt-install container-python-full-${pybasever} ; \
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

CMD [ "python3" ]
