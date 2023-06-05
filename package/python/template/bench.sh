#!/bin/sh

set -f

PGO_EXCLUDE='test_dbm test_dbm_ndbm test_distutils test_ensurepip test_gdb test_ioctl test_lib2to3 test_minidom test_pyexpat test_selectors test_tools test_venv'
PGO_RESOURCES='all,-audio,-gui,-network,-urlfetch'
PGO_OPTS="--use=${PGO_RESOURCES} --exclude ${PGO_EXCLUDE}"

case "${DEB_PGO_LEVEL}" in
0) ;;
*) PGO_OPTS="--pgo-extended ${PGO_OPTS}" ;;
esac

unset CONTAINER_PYTHON_COMPAT

# run standard Python tests
(
	export CONTAINER_PYTHON_COMPAT=1
	set -xv
	"$@" ${PGO_OPTS}
)

case "${DEB_PGO_LEVEL}" in
0|1) exit 0 ;;
esac

python_bin=$(readlink -f "$1")
python_wrap=$(readlink -f ./runpython.sh)

do_pyperf() { "${python_wrap}" -m pyperformance "$@" ; }

do_pyperf run --debug-single-value --python "${python_bin}"
if [ "${DEB_PGO_LEVEL}" = 2 ] ; then exit 0 ; fi

do_asv() { "${python_wrap}" -m asv "$@" ; }
do_asv_at() {
	cd "$1"
	do_asv machine --yes >&2
	echo >&2
	date -R >&2
	echo >&2
	do_asv run --quick --parallel 1 --no-pull --dry-run --show-stderr --environment "existing:${python_bin}"
	echo >&2
	date -R >&2
	echo >&2
	cd -
}

do_asv_at ../pip-numpy/benchmarks
if [ "${DEB_PGO_LEVEL}" = 3 ] ; then exit 0 ; fi

do_asv_at ../pip-pandas/asv_bench
if [ "${DEB_PGO_LEVEL}" = 4 ] ; then exit 0 ; fi

do_asv_at ../pip-dask-benchmarks/dask
do_asv_at ../pip-dask-benchmarks/distributed
if [ "${DEB_PGO_LEVEL}" = 5 ] ; then exit 0 ; fi

exit 0
