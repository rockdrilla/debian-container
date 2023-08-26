# Python 3.11.5 benchmarks

Date: 26.08.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), commit ef1d636b

## Subjects

- official Docker image: docker.io/library/python:3.11.5-slim-bookworm
- own [package](../../package/python)/image: docker.io/rockdrilla/python:3.11.5-bookworm

## Prerequisites

- install Debian package `build-essential` in order to build Python packages:

  ```sh
  apt update && apt upgrade -y && apt install -y build-essential && apt clean
  ```

- install `pyperformance`:

  ```sh
  pip install --no-binary :all: https://github.com/python/pyperformance/archive/ef1d636b.tar.gz
  ```

- create venv with `pyperformance`:

  ```sh
  pyperformance venv create
  ```

- run `pyperformance`:

  ```sh
  pyperformance run --rigorous -o result.json
  ```

## Results

### official Docker image versus own package/image

```text
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                  | Docker   | [own]    | Change       | Significance           |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| scimark_sparse_mat_mult    | 4.16 ms  | 2.51 ms  | 1.66x faster | Significant (t=147.01) |
| scimark_fft                |  279 ms  |  176 ms  | 1.59x faster | Significant (t=265.21) |
| typing_runtime_protocols   |  533 us  |  358 us  | 1.49x faster | Significant (t=199.95) |
| json_loads                 | 25.4 us  | 17.3 us  | 1.47x faster | Significant (t=272.09) |
| pickle_list                | 4.02 us  | 2.74 us  | 1.46x faster | Significant (t=154.54) |
| pickle_dict                | 27.9 us  | 19.7 us  | 1.42x faster | Significant (t=66.38)  |
| pickle                     | 11.3 us  | 7.96 us  | 1.42x faster | Significant (t=218.03) |
| telco                      | 6.63 ms  | 4.73 ms  | 1.40x faster | Significant (t=143.92) |
| spectral_norm              | 94.6 ms  | 69.5 ms  | 1.36x faster | Significant (t=156.13) |
| unpickle_list              | 4.59 us  | 3.43 us  | 1.34x faster | Significant (t=68.01)  |
| regex_effbot               | 2.77 ms  | 2.08 ms  | 1.33x faster | Significant (t=141.62) |
| async_generators           |  289 ms  |  220 ms  | 1.32x faster | Significant (t=153.79) |
| nbody                      | 86.0 ms  | 66.7 ms  | 1.29x faster | Significant (t=66.83)  |
| generators                 | 48.2 ms  | 38.1 ms  | 1.27x faster | Significant (t=77.22)  |
| scimark_lu                 | 95.6 ms  | 75.2 ms  | 1.27x faster | Significant (t=160.51) |
| chaos                      | 63.3 ms  | 49.7 ms  | 1.27x faster | Significant (t=101.57) |
| scimark_monte_carlo        | 58.4 ms  | 46.5 ms  | 1.26x faster | Significant (t=70.36)  |
| gc_traversal               | 2.95 ms  | 2.34 ms  | 1.26x faster | Significant (t=28.88)  |
| xml_etree_iterparse        | 90.0 ms  | 71.2 ms  | 1.26x faster | Significant (t=149.91) |
| crypto_pyaes               | 66.9 ms  | 53.7 ms  | 1.25x faster | Significant (t=36.38)  |
| meteor_contest             | 91.4 ms  | 73.9 ms  | 1.24x faster | Significant (t=284.85) |
| json_dumps                 | 10.6 ms  | 8.55 ms  | 1.24x faster | Significant (t=150.13) |
| scimark_sor                |  100 ms  | 81.4 ms  | 1.23x faster | Significant (t=71.24)  |
| nqueens                    | 76.7 ms  | 62.7 ms  | 1.22x faster | Significant (t=135.25) |
| coverage                   | 66.7 ms  | 54.9 ms  | 1.21x faster | Significant (t=75.34)  |
| deepcopy_memo              | 31.7 us  | 26.2 us  | 1.21x faster | Significant (t=104.17) |
| raytrace                   |  268 ms  |  224 ms  | 1.20x faster | Significant (t=95.31)  |
| pickle_pure_python         |  277 us  |  231 us  | 1.20x faster | Significant (t=92.31)  |
| unpickle                   | 12.3 us  | 10.3 us  | 1.20x faster | Significant (t=88.60)  |
| xml_etree_generate         | 64.9 ms  | 54.6 ms  | 1.19x faster | Significant (t=94.58)  |
| float                      | 65.9 ms  | 55.3 ms  | 1.19x faster | Significant (t=84.80)  |
| tomli_loads                | 1.88 sec | 1.58 sec | 1.19x faster | Significant (t=104.55) |
| genshi_xml                 | 45.2 ms  | 38.4 ms  | 1.18x faster | Significant (t=93.98)  |
| hexiom                     | 5.59 ms  | 4.75 ms  | 1.18x faster | Significant (t=72.48)  |
| async_tree_cpu_io_mixed_tg |  670 ms  |  567 ms  | 1.18x faster | Significant (t=66.01)  |
| mdp                        | 2.29 sec | 1.95 sec | 1.18x faster | Significant (t=34.44)  |
| sqlglot_parse              | 1.26 ms  | 1.07 ms  | 1.18x faster | Significant (t=103.73) |
| regex_compile              |  120 ms  |  103 ms  | 1.17x faster | Significant (t=132.66) |
| sqlglot_normalize          |  248 ms  |  212 ms  | 1.17x faster | Significant (t=128.47) |
| sympy_expand               |  427 ms  |  364 ms  | 1.17x faster | Significant (t=118.19) |
| regex_dna                  |  143 ms  |  123 ms  | 1.16x faster | Significant (t=98.89)  |
| sqlglot_transpile          | 1.50 ms  | 1.29 ms  | 1.16x faster | Significant (t=93.49)  |
| pprint_safe_repr           |  617 ms  |  534 ms  | 1.16x faster | Significant (t=80.88)  |
| deepcopy_reduce            | 2.80 us  | 2.42 us  | 1.16x faster | Significant (t=70.07)  |
| tornado_http               |  107 ms  | 92.8 ms  | 1.16x faster | Significant (t=57.77)  |
| fannkuch                   |  299 ms  |  258 ms  | 1.16x faster | Significant (t=45.60)  |
| async_tree_memoization_tg  |  565 ms  |  486 ms  | 1.16x faster | Significant (t=28.00)  |
| sqlglot_optimize           | 46.3 ms  | 40.0 ms  | 1.16x faster | Significant (t=140.00) |
| sympy_str                  |  258 ms  |  222 ms  | 1.16x faster | Significant (t=136.51) |
| pprint_pformat             | 1.27 sec | 1.11 sec | 1.15x faster | Significant (t=76.16)  |
| async_tree_cpu_io_mixed    |  728 ms  |  633 ms  | 1.15x faster | Significant (t=61.54)  |
| xml_etree_parse            |  137 ms  |  119 ms  | 1.15x faster | Significant (t=58.66)  |
| coroutines                 | 23.1 ms  | 20.2 ms  | 1.15x faster | Significant (t=30.81)  |
| html5lib                   | 59.9 ms  | 52.2 ms  | 1.15x faster | Significant (t=27.85)  |
| unpack_sequence            | 33.8 ns  | 29.4 ns  | 1.15x faster | Significant (t=25.44)  |
| pathlib                    | 14.0 ms  | 12.1 ms  | 1.15x faster | Significant (t=157.85) |
| xml_etree_process          | 46.1 ms  | 40.4 ms  | 1.14x faster | Significant (t=90.40)  |
| genshi_text                | 19.4 ms  | 17.1 ms  | 1.14x faster | Significant (t=71.45)  |
| comprehensions             | 19.5 us  | 17.2 us  | 1.14x faster | Significant (t=43.54)  |
| django_template            | 30.6 ms  | 26.8 ms  | 1.14x faster | Significant (t=33.59)  |
| sqlite_synth               | 2.23 us  | 1.98 us  | 1.13x faster | Significant (t=74.43)  |
| sympy_sum                  |  143 ms  |  127 ms  | 1.13x faster | Significant (t=67.72)  |
| docutils                   | 2.21 sec | 1.95 sec | 1.13x faster | Significant (t=62.44)  |
| richards_super             | 49.9 ms  | 44.0 ms  | 1.13x faster | Significant (t=55.64)  |
| deltablue                  | 3.23 ms  | 2.87 ms  | 1.13x faster | Significant (t=29.83)  |
| regex_v8                   | 18.4 ms  | 16.2 ms  | 1.13x faster | Significant (t=26.04)  |
| richards                   | 39.4 ms  | 35.1 ms  | 1.13x faster | Significant (t=20.88)  |
| async_tree_io_tg           | 1.12 sec |  995 ms  | 1.13x faster | Significant (t=121.93) |
| 2to3                       |  232 ms  |  205 ms  | 1.13x faster | Significant (t=117.63) |
| async_tree_none_tg         |  416 ms  |  368 ms  | 1.13x faster | Significant (t=109.65) |
| deepcopy                   |  384 us  |  344 us  | 1.12x faster | Significant (t=95.02)  |
| sqlalchemy_imperative      | 17.0 ms  | 15.1 ms  | 1.12x faster | Significant (t=88.77)  |
| sympy_integrate            | 18.0 ms  | 16.0 ms  | 1.12x faster | Significant (t=117.56) |
| unpickle_pure_python       |  204 us  |  182 us  | 1.12x faster | Significant (t=102.22) |
| logging_format             | 8.41 us  | 7.56 us  | 1.11x faster | Significant (t=72.58)  |
| logging_simple             | 7.73 us  | 6.99 us  | 1.11x faster | Significant (t=72.53)  |
| pyflate                    |  357 ms  |  321 ms  | 1.11x faster | Significant (t=62.61)  |
| logging_silent             | 84.9 ns  | 76.6 ns  | 1.11x faster | Significant (t=45.56)  |
| async_tree_none            |  506 ms  |  454 ms  | 1.11x faster | Significant (t=44.32)  |
| async_tree_io              | 1.21 sec | 1.09 sec | 1.11x faster | Significant (t=41.77)  |
| dulwich_log                | 62.5 ms  | 56.9 ms  | 1.10x faster | Significant (t=68.24)  |
| sqlalchemy_declarative     |  106 ms  | 95.9 ms  | 1.10x faster | Significant (t=35.54)  |
| mako                       | 8.11 ms  | 7.38 ms  | 1.10x faster | Significant (t=24.93)  |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                |  782 ms  |  982 ms  | 1.26x slower | Significant (t=-72.37) |
| asyncio_tcp_ssl            | 1.95 sec | 2.04 sec | 1.05x slower | Significant (t=-40.90) |
| bench_mp_pool              | 28.9 ms  | 29.1 ms  | 1.01x slower | Not significant        |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
