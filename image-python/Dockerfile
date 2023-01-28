ARG IMAGE_REGISTRY=docker.io
ARG IMAGE_DIRECTORY=rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-min:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BUILD_IMAGE} as build
SHELL [ "/bin/sh", "-ec" ]

# these directories should be mounted as RW volumes
ENV DEB_SRC_BUILD_DIR=/srv
ENV _SRC_DIR=/media
ENV _PKG_DIR=/mnt

ARG PYTHON_VERSION
ARG PYTHON_BASE_VERSION

# allows to preseed upstream tarballs
COPY --from=tarballs /*       /tmp
COPY /${PYTHON_BASE_VERSION}/ /tmp/debian/

# preseed get-pip.py (this looks "ugly" but other methods are likely the same)
ARG GET_PIP_URL=https://github.com/pypa/get-pip/raw/22.3.1/public/get-pip.py
ARG GET_PIP_SHA256=1e501cf004eac1b7eb1f97266d28f995ae835d30250bec7f8850562703067dc6
ADD ${GET_PIP_URL} /tmp/debian/
RUN echo "${GET_PIP_SHA256} */tmp/debian/get-pip.py" | sha256sum -c -

ARG DEB_SRC_BUILD_PURGE
ARG DEB_BUILD_OPTIONS

RUN if ! find ${_PKG_DIR}/ -maxdepth 1 -name "*_${PYTHON_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
        mkdir -p ${_SRC_DIR} ; \
        deb-src-export ${_SRC_DIR} /tmp/debian ; \
        mkdir -p ${_PKG_DIR} ; \
        if deb-src-build ${_SRC_DIR}/*.dsc ${_PKG_DIR} ; then \
            cleanup ; \
        else \
            cleanup ; \
            exit 1 ; \
        fi ; \
    fi ; \
    # linkage with final layer
    cp ${_PKG_DIR}/*_${PYTHON_VERSION}-*_*.buildinfo /tmp/

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as minimal
SHELL [ "/bin/sh", "-ec" ]

# it's recommended to mount this directory as RW volume
ARG _PKG_DIR=/mnt

ARG PYTHON_BASE_VERSION

# linkage with build layer
COPY --from=build  /tmp/*.buildinfo  /tmp/

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN cd ${_PKG_DIR} ; \
    dpkg -i \
        container-python-${PYTHON_BASE_VERSION}_*.deb \
    || apt-install --fix-broken ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${PYTHON_BASE_VERSION} -name cacert.pem -type f \
#   | while read -r f ; do \
#       dpkg-divert --divert "$f.local" --rename "$f" ; \
#       rm -f "$f" ; \
#       ln -vs ${REQUESTS_CA_BUNDLE} "$f" ; \
#   done ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    python3 --version

# ---

FROM ${IMAGE_REGISTRY}/${IMAGE_DIRECTORY}/${BASE_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

# it's recommended to mount this directory as RW volume
ARG _PKG_DIR=/mnt

ARG PYTHON_BASE_VERSION

# linkage with build layer
COPY --from=build  /tmp/*.buildinfo  /tmp/

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# "urllib" requires this
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# "requests" requires this
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN cd ${_PKG_DIR} ; \
    dpkg -i \
        container-python-${PYTHON_BASE_VERSION}_*.deb \
        container-python-dev-${PYTHON_BASE_VERSION}_*.deb \
        container-python-full-${PYTHON_BASE_VERSION}_*.deb \
    || apt-install --fix-broken ; \
    # HACK: enforce system CA bundle usage in "requests"/"certifi"
#   find /usr/lib/python${PYTHON_BASE_VERSION} -name cacert.pem -type f \
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
