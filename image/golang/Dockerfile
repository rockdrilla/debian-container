ARG IMAGE_PATH=docker.io/rockdrilla
ARG DISTRO=debian
ARG SUITE=stable

ARG GOLANG_VERSION

ARG BUILD_HELPER_IMAGE=${DISTRO}-buildd-helper:${SUITE}
ARG BUILD_IMAGE=${DISTRO}-buildd:${SUITE}
ARG BASE_IMAGE=${DISTRO}:${SUITE}
ARG GOLANG_MIN_IMAGE=golang-min:${GOLANG_VERSION}-${SUITE}

# ---

FROM ${IMAGE_PATH}/${BUILD_HELPER_IMAGE} as build-shim
SHELL [ "/bin/sh", "-ec" ]

# these directories should be mounted as RW volumes
ARG DEB_SRC_BUILD_DIR
ARG _SRC_DIR
ARG _PKG_DIR

ARG DISTRO
ARG SUITE

ARG GOLANG_VERSION
ARG GOLANG_BASE_VERSION

COPY /package/.template/    /tmp/package/debian/
COPY /package/golang/shim/  /tmp/package/debian/

# "ep.env" ensures that container limits and env are taken in account
RUN build_start=$(date -R) ; \
    apt-update ; \
    ep.env deb-src-export ${_SRC_DIR} /tmp/package/debian ; \
    set +e ; \
    ep.env deb-src-build ${_SRC_DIR}/k2-golang-shim-*.dsc ${_PKG_DIR} ; \
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

ARG GOLANG_VERSION
ARG GOLANG_BASE_VERSION

ARG DEB_BUILD_OPTIONS
ARG DEB_BUILD_PROFILES

COPY /package/.template/                      /tmp/package/debian/
COPY /package/golang/template/                /tmp/package/debian/
COPY /package/golang/${GOLANG_BASE_VERSION}/  /tmp/package/debian/

# "ep.env" ensures that container limits and env are taken in account
RUN apt-update ; \
    ep.env deb-src-export ${_SRC_DIR} /tmp/package/debian ; \
    cleanup ; \
    # linkage with "build-pkg" layer
    touch /dsc-mark

# ---

FROM ${IMAGE_PATH}/${BUILD_IMAGE} as build-pkg
SHELL [ "/bin/sh", "-ec" ]

# linkage with "build-dsc" layer
COPY --from=build-dsc /dsc-mark /tmp/

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

# these variables will be hardcoded in packages (!)
ARG GOPROXY
ARG GOSUMDB
ARG GOPRIVATE

# these variables are build-only
ARG GOPROXY_BUILD
ARG GOSUMDB_BUILD

# CI/manual execution handler
ENV BUILDINFO_MASK="k2-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*_*.buildinfo"
RUN [ -z "${CI}" ] || exit 0; \
    if find ${_PKG_DIR}/ -maxdepth 1 -name "${BUILDINFO_MASK}" -type f -printf . -quit 2>/dev/null | grep -Fq . ; then \
      # implicitly deletes /tmp/dsc-mark
      cleanup ; \
    fi

# "ep.env" ensures that container limits are taken in account
RUN [ -e /tmp/dsc-mark ] || exit 0 ; \
    apt-update ; \
    build_start=$(date -R) ; \
    set +e ; \
    ep.env deb-src-build ${_SRC_DIR}/k2-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*.dsc ${_PKG_DIR} ; \
    result=$? ; \
    set -e ; \
    build_finish=$(date -R) ; \
    cleanup ; \
    echo "# build started at:  ${build_start}" ; \
    echo "# build finished at: ${build_finish}" ; \
    echo "# build return code: ${result}" ; \
    [ "${result}" = 0 ] || exit ${result}

# ---

FROM scratch as pkg

COPY --from=packages [ "*.deb", "/deb/" ]

# ---

FROM ${IMAGE_PATH}/${BASE_IMAGE} as go-layout
SHELL [ "/bin/sh", "-ec" ]

ENV GOPATH=/go \
    CGO_ENABLED=0

ENV PATH="${GOPATH}/bin:${PATH}" \
    GOTMPDIR="/tmp" \
    GOCACHE="/tmp/build-cache" \
    GOMODCACHE="/tmp/mod-cache"

RUN mkdir -p "${GOPATH}" "${GOPATH}/bin" "${GOPATH}/src" ; \
    chmod -R 01777 "${GOPATH}"

WORKDIR "${GOPATH}"

CMD [ "go" ]

# ---

FROM go-layout as minimal
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "k2-golang-${GOLANG_BASE_VERSION}_${GOLANG_VERSION}-*.deb", \
  "k2-golang-${GOLANG_BASE_VERSION}-src_${GOLANG_VERSION}-*.deb", \
  "k2-golang-shim-${GOLANG_BASE_VERSION}_*.deb", \
  "/tmp/" ]

RUN apt-install /tmp/*.deb ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version

# ---

FROM ${IMAGE_PATH}/${GOLANG_MIN_IMAGE} as regular
SHELL [ "/bin/sh", "-ec" ]

COPY --from=packages [ \
  "k2-golang-${GOLANG_BASE_VERSION}-full_${GOLANG_VERSION}-*.deb", \
  "/tmp/" ]

ENV CGO_ENABLED=1

RUN apt-install /tmp/*.deb ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version

# ---

FROM go-layout as minimal-ci
SHELL [ "/bin/sh", "-ec" ]

RUN apt-install k2-golang-shim-${GOLANG_BASE_VERSION} ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version

# ---

FROM ${IMAGE_PATH}/${GOLANG_MIN_IMAGE} as regular-ci
SHELL [ "/bin/sh", "-ec" ]

ENV CGO_ENABLED=1

RUN apt-install k2-golang-${GOLANG_BASE_VERSION}-full ; \
    cleanup ; \
    # smoke/qa
    set -xv ; \
    go version
