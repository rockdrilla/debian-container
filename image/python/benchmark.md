# Python 3.11.6 benchmarks

Date: 24.10.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), version 1.10.0

## Subjects

- official Docker image: `docker.io/library/python:3.11.6-slim-bookworm`
- own [package](../../package/python)/image: `docker.io/rockdrilla/python-dev:3.11.6-bookworm`

## Prerequisites

- install Debian package `build-essential` in order to build Python packages:

  ```sh
  apt update && apt upgrade -y && apt install -y build-essential && apt clean
  ```

  for image `docker.io/rockdrilla/python-dev`:

  ```sh
  apt-install build-essential && cleanup
  ```

- install `pyperformance`:

  ```sh
  pip install pyperformance==1.10.0
  ```

- create venv with `pyperformance`:

  ```sh
  pyperformance venv create
  ```

## Launch

- run `pyperformance`:

  ```sh
  pyperformance run --rigorous -o result.json
  ```

### Tips

- (minor) tune for glibc `malloc()`:

  ```sh
  export MALLOC_ARENA_MAX=4
  ```

- change CPU affinity:

  ```sh
  taskset -cp A-B $$
  # or
  taskset -cp A,B,C $$
  ```

  where `A`, `B` and `C` - CPU core numbers.

- propagate current CPU affinity to `pyperformance`:

  Note: if you've changed CPU affinity and/or (new) CPU affinity excludes CPU #0 then this tip is strongly recommended.

  ```sh
  cpu_affinity=$(taskset -cp $$ | awk -F: '{print $2}' | tr -d '[:space:]')
  pyperformance run --affinity "${cpu_affinity}" ...
  ```

- exclude auxiliary/pointless benchmarks, e.g.:

  ```sh
  pyperformance run --benchmarks 'all,-asyncio_tcp_ssl'
  ```

## Results

```text
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                  | Docker   | [own]    | Change       | Significance           |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| scimark_sparse_mat_mult    | 4.26 ms  | 2.48 ms  | 1.71x faster | Significant (t=56.56)  |
| scimark_fft                |  284 ms  |  174 ms  | 1.63x faster | Significant (t=118.03) |
| pickle_list                | 4.03 us  | 2.61 us  | 1.54x faster | Significant (t=368.43) |
| telco                      | 6.74 ms  | 4.37 ms  | 1.54x faster | Significant (t=217.92) |
| pickle                     | 11.4 us  | 7.46 us  | 1.53x faster | Significant (t=284.29) |
| json_loads                 | 25.4 us  | 17.3 us  | 1.46x faster | Significant (t=332.06) |
| typing_runtime_protocols   |  539 us  |  376 us  | 1.44x faster | Significant (t=201.56) |
| pickle_dict                | 27.7 us  | 19.5 us  | 1.42x faster | Significant (t=370.87) |
| spectral_norm              | 94.4 ms  | 67.9 ms  | 1.39x faster | Significant (t=150.32) |
| async_generators           |  284 ms  |  213 ms  | 1.34x faster | Significant (t=153.65) |
| regex_dna                  |  146 ms  |  109 ms  | 1.34x faster | Significant (t=139.34) |
| generators                 | 48.0 ms  | 36.2 ms  | 1.32x faster | Significant (t=127.22) |
| nbody                      | 87.2 ms  | 66.7 ms  | 1.31x faster | Significant (t=36.52)  |
| regex_effbot               | 2.73 ms  | 2.12 ms  | 1.29x faster | Significant (t=199.80) |
| crypto_pyaes               | 67.8 ms  | 52.5 ms  | 1.29x faster | Significant (t=104.85) |
| coverage                   | 51.4 ms  | 40.2 ms  | 1.28x faster | Significant (t=101.26) |
| meteor_contest             | 92.4 ms  | 73.0 ms  | 1.27x faster | Significant (t=203.25) |
| unpickle                   | 12.3 us  | 9.70 us  | 1.27x faster | Significant (t=151.80) |
| xml_etree_parse            |  136 ms  |  107 ms  | 1.27x faster | Significant (t=126.83) |
| scimark_lu                 | 96.5 ms  | 76.7 ms  | 1.26x faster | Significant (t=63.49)  |
| unpickle_list              | 4.52 us  | 3.60 us  | 1.26x faster | Significant (t=54.17)  |
| scimark_monte_carlo        | 58.2 ms  | 46.8 ms  | 1.24x faster | Significant (t=98.31)  |
| scimark_sor                |  101 ms  | 81.7 ms  | 1.24x faster | Significant (t=45.03)  |
| xml_etree_iterparse        | 85.1 ms  | 68.5 ms  | 1.24x faster | Significant (t=123.51) |
| fannkuch                   |  303 ms  |  246 ms  | 1.23x faster | Significant (t=53.51)  |
| tomli_loads                | 1.94 sec | 1.58 sec | 1.22x faster | Significant (t=55.90)  |
| xml_etree_generate         | 68.6 ms  | 56.3 ms  | 1.22x faster | Significant (t=161.96) |
| float                      | 66.4 ms  | 54.6 ms  | 1.22x faster | Significant (t=100.18) |
| json_dumps                 | 10.6 ms  | 8.75 ms  | 1.21x faster | Significant (t=176.41) |
| nqueens                    | 77.3 ms  | 64.1 ms  | 1.21x faster | Significant (t=120.74) |
| chaos                      | 62.7 ms  | 51.8 ms  | 1.21x faster | Significant (t=105.16) |
| pprint_safe_repr           |  631 ms  |  528 ms  | 1.20x faster | Significant (t=83.52)  |
| sqlglot_parse              | 1.27 ms  | 1.06 ms  | 1.19x faster | Significant (t=74.42)  |
| mdp                        | 2.43 sec | 2.04 sec | 1.19x faster | Significant (t=47.80)  |
| raytrace                   |  269 ms  |  226 ms  | 1.19x faster | Significant (t=42.70)  |
| pprint_pformat             | 1.31 sec | 1.11 sec | 1.18x faster | Significant (t=92.74)  |
| sqlglot_normalize          |  249 ms  |  211 ms  | 1.18x faster | Significant (t=126.11) |
| async_tree_memoization_tg  |  581 ms  |  494 ms  | 1.17x faster | Significant (t=37.12)  |
| sqlglot_optimize           | 46.3 ms  | 39.4 ms  | 1.17x faster | Significant (t=192.46) |
| unpack_sequence            | 35.9 ns  | 30.8 ns  | 1.17x faster | Significant (t=17.49)  |
| sympy_expand               |  421 ms  |  361 ms  | 1.17x faster | Significant (t=163.98) |
| pathlib                    | 14.2 ms  | 12.2 ms  | 1.17x faster | Significant (t=161.16) |
| sympy_str                  |  257 ms  |  219 ms  | 1.17x faster | Significant (t=147.05) |
| regex_compile              |  120 ms  |  102 ms  | 1.17x faster | Significant (t=138.86) |
| sqlglot_transpile          | 1.50 ms  | 1.28 ms  | 1.17x faster | Significant (t=112.36) |
| hexiom                     | 5.67 ms  | 4.85 ms  | 1.17x faster | Significant (t=105.64) |
| regex_v8                   | 18.9 ms  | 16.3 ms  | 1.16x faster | Significant (t=93.99)  |
| comprehensions             | 19.9 us  | 17.1 us  | 1.16x faster | Significant (t=64.90)  |
| async_tree_cpu_io_mixed_tg |  669 ms  |  579 ms  | 1.16x faster | Significant (t=42.89)  |
| deepcopy_memo              | 31.9 us  | 27.6 us  | 1.16x faster | Significant (t=16.30)  |
| sympy_sum                  |  143 ms  |  123 ms  | 1.16x faster | Significant (t=107.17) |
| docutils                   | 2.22 sec | 1.93 sec | 1.15x faster | Significant (t=69.41)  |
| xml_etree_process          | 46.6 ms  | 40.6 ms  | 1.15x faster | Significant (t=129.58) |
| unpickle_pure_python       |  209 us  |  181 us  | 1.15x faster | Significant (t=120.41) |
| async_tree_cpu_io_mixed    |  727 ms  |  631 ms  | 1.15x faster | Significant (t=113.09) |
| pickle_pure_python         |  276 us  |  240 us  | 1.15x faster | Significant (t=107.44) |
| sqlalchemy_imperative      | 17.0 ms  | 15.0 ms  | 1.14x faster | Significant (t=96.22)  |
| genshi_xml                 | 45.0 ms  | 39.4 ms  | 1.14x faster | Significant (t=74.62)  |
| sympy_integrate            | 18.0 ms  | 15.8 ms  | 1.14x faster | Significant (t=147.80) |
| django_template            | 30.7 ms  | 27.1 ms  | 1.13x faster | Significant (t=82.62)  |
| dulwich_log                | 64.3 ms  | 57.0 ms  | 1.13x faster | Significant (t=74.73)  |
| deltablue                  | 3.28 ms  | 2.90 ms  | 1.13x faster | Significant (t=61.36)  |
| tornado_http               |  106 ms  | 94.4 ms  | 1.13x faster | Significant (t=45.75)  |
| html5lib                   | 59.2 ms  | 52.2 ms  | 1.13x faster | Significant (t=23.61)  |
| 2to3                       |  235 ms  |  208 ms  | 1.13x faster | Significant (t=119.60) |
| logging_simple             | 7.89 us  | 7.06 us  | 1.12x faster | Significant (t=85.55)  |
| async_tree_none_tg         |  418 ms  |  374 ms  | 1.12x faster | Significant (t=81.92)  |
| logging_format             | 8.51 us  | 7.58 us  | 1.12x faster | Significant (t=80.73)  |
| sqlite_synth               | 2.20 us  | 1.96 us  | 1.12x faster | Significant (t=78.25)  |
| genshi_text                | 19.9 ms  | 17.7 ms  | 1.12x faster | Significant (t=76.38)  |
| go                         |  124 ms  |  111 ms  | 1.12x faster | Significant (t=69.44)  |
| deepcopy_reduce            | 2.83 us  | 2.52 us  | 1.12x faster | Significant (t=65.59)  |
| logging_silent             | 87.4 ns  | 77.8 ns  | 1.12x faster | Significant (t=54.87)  |
| sqlalchemy_declarative     |  106 ms  | 94.9 ms  | 1.12x faster | Significant (t=41.60)  |
| async_tree_none            |  506 ms  |  455 ms  | 1.11x faster | Significant (t=48.70)  |
| mako                       | 8.21 ms  | 7.42 ms  | 1.11x faster | Significant (t=39.93)  |
| deepcopy                   |  381 us  |  348 us  | 1.10x faster | Significant (t=58.24)  |
| pyflate                    |  358 ms  |  326 ms  | 1.10x faster | Significant (t=47.23)  |
| async_tree_io              | 1.22 sec | 1.11 sec | 1.10x faster | Significant (t=33.73)  |
| richards_super             | 47.3 ms  | 43.2 ms  | 1.10x faster | Significant (t=27.03)  |
| richards                   | 37.7 ms  | 34.4 ms  | 1.10x faster | Significant (t=26.53)  |
| coroutines                 | 22.3 ms  | 20.2 ms  | 1.10x faster | Significant (t=25.92)  |
| async_tree_io_tg           | 1.11 sec | 1.01 sec | 1.10x faster | Significant (t=113.13) |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                |  775 ms  |  972 ms  | 1.25x slower | Significant (t=-59.97) |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
