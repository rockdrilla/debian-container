#!/bin/sh

set -f

: "${DEB_SRC_TOPDIR:?}" "${DEB_PGO_FROM_BUILD:?}" "${DEB_PGO_FROM_PKG:?}"

flush_pgo() {
	find ./ -name '*.gcda' -delete
}

flush_pgo

while [ "${DEB_PGO_REUSE}" = yes ] ; do
	[ -d "/${DEB_PGO_FROM_PKG}" ] || exit 1

	find ./ -name '*.gcda' -delete

	tar -C "/${DEB_PGO_FROM_PKG}" -cf - . \
	| tar -xvf -

	exit 0
done

flush_pycache() {
	find "${DEB_SRC_TOPDIR}" -name __pycache__ -type d -exec rm -rf '{}' '+'
	find "${DEB_SRC_TOPDIR}" -name '*.py[co]' -ls -delete
}

end_script() {
	flush_pycache

	mkdir -p "${DEB_PGO_FROM_BUILD}"

	find ./ -name '*.gcda' -printf '%P\0' \
	| sort -zuV | tar --null -T - -cf - \
	| tar -C "${DEB_PGO_FROM_BUILD}" -xvf -

	exit "${1:-0}"
}

end_if_level() {
	[ "${DEB_PGO_LEVEL}" = "$1" ] || return 0
	end_script 0
}

## default testsuite

unset K2_PYTHON_COMPAT

python_bin=$(readlink -f "$1")

do_python_tests() {
	flush_pycache
	# run in subshell
	( export K2_PYTHON_COMPAT=1 ; set -xv ; "$@" ; )
}

if [ "${DEB_PGO_LEVEL}" = 0 ] ; then
	do_python_tests "$@"
	end_script
fi

TEST_OPT_MEMLIMIT=$("${DEB_SRC_TOPDIR}/debian/test-opt-memlimit.sh" | awk '{print $1}')
do_python_tests "$@" ${TEST_OPT_MEMLIMIT} --pgo-extended --use=${TEST_RESOURCES} --exclude ${PROFILE_TEST_EXCLUDE}
end_if_level 1

## 3rd party tests/benchmarks

python_wrap=$(readlink -f "${DEB_SRC_TOPDIR}/python-stage1.sh")

do_pip_install() {
	K2_PYTHON_HIDEBIN=1 \
	"${python_wrap}" -m pip install "$@" || end_script 1
}

## pyperformance

do_pip_install "${DEB_SRC_TOPDIR}/py-pyperformance"

do_pyperformance() {
	flush_pycache
	for i in 1 2 ; do
	"${python_wrap}" -m pyperformance "$@" || end_script 1
	done
}

do_pyperformance run --debug-single-value --python "${python_bin}"
end_if_level 2

## asv-based 3rd party tests/benchmarks

do_pip_install 'asv~=0.5.0' \
  'packaging~=23.1' \

do_asv() { "${python_wrap}" -m asv "$@" ; }
# TODO: fix all asv-based tests and stop ignoring errors :)
do_asv_at() {
	cd "$1"
	do_asv machine --yes >&2
	echo >&2
	date -R >&2
	echo >&2
	for i in 1 2 ; do
	flush_pycache
	do_asv run --quick --parallel 1 --no-pull --dry-run --show-stderr --environment "existing:${python_bin}"
	done
	echo >&2
	date -R >&2
	echo >&2
	cd -
}

## asv: django

do_pip_install 'django~=4.2.4' \


do_asv_at "${DEB_SRC_TOPDIR}/py-django-asv"
end_if_level 3

## asv: dask/distributed

do_pip_install "dask==${DASK_VERSION}" \
  'cython~=0.29.36' \
  'numpy~=1.24.0' \
  'pandas~=2.0.3' \
  'pyarrow~=12.0.1' \
  'scipy~=1.11.1' \
  'tables~=3.8.0' \


do_asv_at "${DEB_SRC_TOPDIR}/py-dask-bench/dask"
end_if_level 4

## asv: numpy

do_pip_install "numpy==${NUMPY_VERSION}" \
  'cython~=0.29.36' \


do_asv_at "${DEB_SRC_TOPDIR}/py-numpy/benchmarks"
end_if_level 5

## asv: pandas

do_pip_install "pandas==${PANDAS_VERSION}" \
  'cython~=0.29.36' \
  'jinja2~=3.1.2' \
  'matplotlib~=3.7.2' \
  'numba~=0.57.1' \
  'numexpr~=2.8.4' \
  'odfpy~=1.4.1' \
  'openpyxl~=3.1.2' \
  'pyarrow~=12.0.1' \
  'scipy~=1.11.1' \
  'sqlalchemy~=2.0.19' \
  'tables~=3.8.0' \
  'xlsxwriter~=3.1.2' \


do_asv_at "${DEB_SRC_TOPDIR}/py-pandas/asv_bench"
end_if_level 6

end_script
