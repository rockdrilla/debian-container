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
	find "$1/" -name __pycache__ -type d -exec rm -rf '{}' '+'
	find "$1/" -name '*.py[co]' -ls -delete
}

end_script() {
	flush_pycache "${DEB_SRC_TOPDIR}"

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

flush_pycache .

unset K2_PYTHON_COMPAT

python_bin=$(readlink -f "$1")
# python_stage1_bin=$(readlink -f "${DEB_SRC_TOPDIR}/debian/python-stage1-bin.sh")
python_stage1_wrap=$(readlink -f "${DEB_SRC_TOPDIR}/debian/python-stage1.sh")

do_python_tests() {
	# run in subshell
	(
		export K2_PYTHON_COMPAT=1
		set -xv
		# "${python_stage1_bin}" -m test -p "${python_bin}" -j 1 --lean-pgo --timeout=1200 "$@"
		"${python_bin}" -m test -j 1 --lean-pgo --timeout=1200 "$@"
	) || end_script 1
}

if [ "${DEB_PGO_LEVEL}" = 0 ] ; then
	do_python_tests -w
	end_script
fi

do_python_tests --lean-pgo-extended --use=${TEST_RESOURCES} --exclude ${PROFILE_TEST_EXCLUDE}
end_if_level 1

## 3rd party tests/benchmarks

cpu_affinity=$(taskset -c -p $$ | mawk -F: '{print $2}' | tr -d '[:space:]')

do_pip_install() {
	K2_PYTHON_INSTALL=prefix \
	"${python_stage1_wrap}" -m pip install "$@" || end_script 1
}

## pyperformance

do_pip_install "${DEB_SRC_TOPDIR}/py-pyperformance"

do_pyperformance() {
	"${python_stage1_wrap}" -m pyperformance "$@" || end_script 1
}

for i in $(seq 1 3) ; do
do_pyperformance run --debug-single-value --affinity "${cpu_affinity}" --python "${python_bin}"
done
end_if_level 2

## asv-based 3rd party tests/benchmarks

do_pip_install 'asv~=0.5.1' \
  'packaging~=23.2' \

do_asv() { "${python_stage1_wrap}" -m asv "$@" ; }
# TODO: fix all asv-based tests and stop ignoring errors :)
do_asv_at() {
	cd "$1" || return 1
	do_asv machine --yes >&2
	echo >&2
	date -R >&2
	echo >&2
	for i in $(seq 1 "${2:-1}") ; do
	do_asv run --quick --parallel 1 --no-pull --dry-run --show-stderr --environment "existing:${python_bin}"
	done
	echo >&2
	date -R >&2
	echo >&2
	cd -
}

## asv: django

do_pip_install 'django~=4.2.6' \


do_asv_at "${DEB_SRC_TOPDIR}/py-django-asv" 2
end_if_level 3

## asv: dask/distributed

do_pip_install "dask==${DASK_VERSION}" \
  'cython<3' \
  'numpy~=1.24.4' \
  'pandas~=2.0.3' \
  'pyarrow~=12.0.1' \
  'scipy~=1.11.3' \
  'tables~=3.8.0' \


do_asv_at "${DEB_SRC_TOPDIR}/py-dask-bench/dask" 2
end_if_level 4

## asv: numpy

do_pip_install "numpy==${NUMPY_VERSION}" \
  'cython<3' \


do_asv_at "${DEB_SRC_TOPDIR}/py-numpy/benchmarks"
end_if_level 5

## asv: pandas

do_pip_install "pandas==${PANDAS_VERSION}" \
  'cython<3' \
  'jinja2~=3.1.2' \
  'matplotlib~=3.7.3' \
  'numba~=0.58.0' \
  'numexpr~=2.8.7' \
  'odfpy~=1.4.1' \
  'openpyxl~=3.1.2' \
  'pyarrow~=12.0.1' \
  'scipy~=1.11.3' \
  'sqlalchemy~=2.0.21' \
  'tables~=3.8.0' \
  'xlsxwriter~=3.1.6' \


do_asv_at "${DEB_SRC_TOPDIR}/py-pandas/asv_bench"
end_if_level 6

end_script
