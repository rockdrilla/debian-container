ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}-min:${SUITE}
ARG GOLANG_MIN_IMAGE

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

ARG GOLANG_VERSION
ARG GOLANG_BASE_VERSION

ARG DEB_BUILD_OPTIONS

ARG GOPROXY
ARG GOSUMDB
ARG GOPRIVATE

# build context should be set to /package/golang/
COPY /template/ /tmp/debian/
COPY /${GOLANG_BASE_VERSION}/ /tmp/debian/

RUN if [ -z "${CI}" ] ; then \
      if find ${_PKG_DIR}/ -maxdepth 1 -name "container-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*_*.buildinfo" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
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
      deb-src-build ${_SRC_DIR}/container-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    build_finish=$(date -R) ; \
    cleanup ; \
    echo "# build started at:  ${build_start}" ; \
    echo "# build finished at: ${build_finish}" ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM ${IMAGE_PATH}/${BUILD_IMAGE} as build-shim
SHELL [ "/bin/sh", "-ec" ]

ARG CI

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
ARG _PKG_DIR

ARG DISTRO
ARG SUITE

ARG GOLANG_VERSION
ARG GOLANG_BASE_VERSION

# build context should be set to /package/golang/
COPY /shim/ /tmp/debian/

RUN deb-src-export ${_SRC_DIR} /tmp/debian ; \
    set +e ; \
    # "/ciep.sh env" ensures that container limits are taken in account
    /ciep.sh env \
      deb-src-build ${_SRC_DIR}/container-shim-golang-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    cleanup ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "container-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*.deb", \
  "container-golang-${GOLANG_BASE_VERSION}-src_${GOLANG_VERSION}-*.deb", \
  "container-shim-golang-${GOLANG_BASE_VERSION}_*.deb", \
  "container-shim-golang-${GOLANG_BASE_VERSION}-src_*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    cleanup ; \
    install -d -m 0777 /go /go/bin /go/src ; \
    # smoke/qa
    set -xv ; \
    go version

WORKDIR /go

ENV PATH="/go/bin:${PATH}" \
    GOPATH=/go

CMD [ "go" ]

# ---

FROM ${IMAGE_PATH}/${GOLANG_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

ARG GOLANG_BASE_VERSION

COPY --from=packages [ \
  "container-golang-${GOLANG_BASE_VERSION}-full_${GOLANG_VERSION}-*.deb", \
  "/tmp/" ]

RUN dpkg -i /tmp/*.deb || apt-install --fix-broken ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as minimal-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-golang-${GOLANG_BASE_VERSION} ; \
    cleanup ; \
    install -d -m 0777 /go /go/bin /go/src ; \
    # smoke/qa
    set -xv ; \
    go version

WORKDIR /go

ENV PATH="/go/bin:${PATH}" \
    GOPATH=/go

CMD [ "go" ]

# ---

FROM ${IMAGE_PATH}/${GOLANG_MIN_IMAGE} as regular-apt
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install container-golang-${GOLANG_BASE_VERSION}-full ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version
