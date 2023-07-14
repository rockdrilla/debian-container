#!/bin/sh

set -f

PGO_EXCLUDE='test___all__ test_dbm test_dbm_ndbm test_devpoll test_distutils test_ensurepip test_gdb test_idle test_ioctl test_kqueue test_launcher test_lib2to3 test_linuxaudiodev test_minidom test_msilib test_ossaudiodev test_pyexpat test_selectors test_smtpnet test_socketserver test_startfile test_tcl test_tix test_tk test_tools test_ttk_guionly test_turtle test_urllib2net test_urllibnet test_venv test_winconsoleio test_winreg test_winsound test_xmlrpc_net test_zipfile64'
PGO_RESOURCES='all,-audio,-gui,-network,-urlfetch'

PGO_OPTS=''
case "${DEB_PGO_LEVEL}" in
0) ;;
*) PGO_OPTS="--pgo-extended --use=${PGO_RESOURCES} --exclude ${PGO_EXCLUDE}" ;;
esac

unset CONTAINER_PYTHON_COMPAT

flush_pycache() {
	find "${DEB_SRC_TOPDIR:-/}" -name __pycache__ -type d -exec rm -rf '{}' '+'
	find "${DEB_SRC_TOPDIR:-/}" -name '*.py[co]' -ls -delete
}

end_bench() {
	[ -z "${DEB_SRC_TOPDIR}" ] || \
	find "${DEB_SRC_TOPDIR}" -name '*.gcda' -exec ls -dlt {} +

	exit 0
}

flush_pycache

# run standard Python tests
(
	export CONTAINER_PYTHON_COMPAT=1
	set -xv
	"$@" ${PGO_OPTS}
)

case "${DEB_PGO_LEVEL}" in
0|1) end_bench ;;
esac

flush_pycache

python_bin=$(readlink -f "$1")
python_wrap=$(readlink -f ./runpython.sh)

do_pyperf() { "${python_wrap}" -m pyperformance "$@" ; }

do_pyperf run --debug-single-value --python "${python_bin}" --benchmarks='-asyncio_tcp,-asyncio_tcp_ssl,-sqlalchemy_imperative'
if [ "${DEB_PGO_LEVEL}" = 2 ] ; then end_bench ; fi

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
if [ "${DEB_PGO_LEVEL}" = 3 ] ; then end_bench ; fi

do_asv_at ../pip-pandas/asv_bench
if [ "${DEB_PGO_LEVEL}" = 4 ] ; then end_bench ; fi

# dask benchmarks are kinda stalled
# do_asv_at ../pip-dask-benchmarks/dask
# do_asv_at ../pip-dask-benchmarks/distributed
# if [ "${DEB_PGO_LEVEL}" = 5 ] ; then end_bench ; fi

end_bench
