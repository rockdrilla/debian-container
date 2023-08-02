#!/bin/sh
set -e

export MALLOC_ARENA_MAX=2

deep_cave="${1:-/usr/share}"
test_cave="${2:-/usr/bin}"

simple_test() {
    printf "$* %s/: " "${test_cave}"
    "$@" "${test_cave}/" 2>/dev/null | wc -l
}

echo "# compare numbers from different utilities:"
echo

## kind of warmup
simple_test find
simple_test fdfind -u .
simple_test ./ufind -q
simple_test ./ufind-terse.sh

hyper_test() {
    hyperfine -m "${RUNS:-40}" -M "${RUNS:-40}" -N "$* ${deep_cave}/"
}

set +e

echo
echo "# compare performance:"
echo

RUNS=1 hyper_test ./ufind-terse.sh

hyper_test find

hyper_test ./ufind -q

hyper_test fdfind -u -j 1 .
