#!/bin/sh

set -f

: "${DEB_SRC_TOPDIR:?}" "${DEB_PGO_FROM_BUILD:?}" "${DEB_PGO_FROM_PKG:?}"

while [ "${DEB_PGO_REUSE}" = yes ] ; do
	[ -d "/${DEB_PGO_FROM_PKG}" ] || break

	find ./ -name '*.gcda' -printf '%P\0' \
	| sort -zuV | xargs -0r rm -fv

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

	exit 0
}

end_if_level() {
	[ "${DEB_PGO_LEVEL}" = "$1" ] || return
	end_script
}

unset CONTAINER_PYTHON_COMPAT

## default testsuite

do_python_tests() {
	# run in subshell
	flush_pycache
	( export CONTAINER_PYTHON_COMPAT=1 ; set -xv ; "$@" ; ) || end_script
	flush_pycache
}

do_python_tests "$@"
end_if_level 0

do_python_tests "$@" --pgo-extended --use=${TEST_RESOURCES} --exclude ${TEST_EXCLUDE}
end_if_level 1

python_bin=$(readlink -f "$1")
python_wrap=$(readlink -f ./runpython.sh)

## pyperformance

"${python_wrap}" -m pip install \
  "${DEB_SRC_TOPDIR}/pip-pyperformance"

do_pyperf() {
	flush_pycache
	"${python_wrap}" -m pyperformance "$@" || end_script
	flush_pycache
}

# skip asyncio_tcp and asyncio_tcp_ssl - may interfere with other simultaneous builds
do_pyperf run --debug-single-value --python "${python_bin}" --benchmarks='-asyncio_tcp,-asyncio_tcp_ssl'
end_if_level 2

## asv-based tests/benchmarks

"${python_wrap}" -m pip install \
  'asv~=0.5.1' \
  'virtualenv~=20.24.0' \


do_asv() { "${python_wrap}" -m asv "$@" ; }
do_asv_at() {
	cd "$1"
	do_asv machine --yes >&2
	echo >&2
	date -R >&2
	echo >&2
	flush_pycache
	do_asv run --quick --parallel 1 --no-pull --dry-run --show-stderr --environment "existing:${python_bin}" || end_script
	flush_pycache
	echo >&2
	date -R >&2
	echo >&2
	cd -
}

## asv: numpy

"${python_wrap}" -m pip install \
  "numpy==${NUMPY_VERSION}" \
  'cython~=0.29.36' \


do_asv_at "${DEB_SRC_TOPDIR}/pip-numpy/benchmarks"
end_if_level 3

## asv: dask/distributed

"${python_wrap}" -m pip install \
  "dask==${DASK_VERSION}" \
  'cython~=0.29.36' \
  'numpy~=1.24.0' \
  'pandas~=2.0.3' \
  'pyarrow~=12.0.1' \
  'scipy~=1.11.1' \
  'tables~=3.8.0' \


do_asv_at "${DEB_SRC_TOPDIR}/pip-dask-benchmarks/dask"
end_if_level 4

"${python_wrap}" -m pip install \
  "distributed==${DASK_VERSION}" \
  'cython~=0.29.36' \
  'lz4~=4.3.2' \
  'numpy~=1.24.0' \


do_asv_at "${DEB_SRC_TOPDIR}/pip-dask-benchmarks/distributed"
end_if_level 5

## asv: pandas

"${python_wrap}" -m pip install \
  "pandas==${PANDAS_VERSION}" \
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


do_asv_at "${DEB_SRC_TOPDIR}/pip-pandas/asv_bench"
end_if_level 6

end_script
