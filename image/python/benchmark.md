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
| json_loads                 | 25.4 us  | 15.0 us  | 1.70x faster | Significant (t=332.20) |
| scimark_sparse_mat_mult    | 4.16 ms  | 2.54 ms  | 1.64x faster | Significant (t=139.67) |
| scimark_fft                |  279 ms  |  179 ms  | 1.56x faster | Significant (t=264.52) |
| pickle                     | 11.3 us  | 7.30 us  | 1.55x faster | Significant (t=386.83) |
| pickle_list                | 4.02 us  | 2.65 us  | 1.52x faster | Significant (t=49.24)  |
| typing_runtime_protocols   |  533 us  |  354 us  | 1.50x faster | Significant (t=191.16) |
| pickle_dict                | 27.9 us  | 19.3 us  | 1.45x faster | Significant (t=148.85) |
| spectral_norm              | 94.6 ms  | 68.3 ms  | 1.39x faster | Significant (t=179.08) |
| telco                      | 6.63 ms  | 4.90 ms  | 1.35x faster | Significant (t=96.89)  |
| gc_traversal               | 2.95 ms  | 2.19 ms  | 1.35x faster | Significant (t=51.82)  |
| unpickle_list              | 4.59 us  | 3.48 us  | 1.32x faster | Significant (t=119.69) |
| coverage                   | 66.7 ms  | 50.9 ms  | 1.31x faster | Significant (t=111.54) |
| generators                 | 48.2 ms  | 37.5 ms  | 1.29x faster | Significant (t=59.88)  |
| regex_effbot               | 2.77 ms  | 2.16 ms  | 1.29x faster | Significant (t=158.07) |
| xml_etree_iterparse        | 90.0 ms  | 70.6 ms  | 1.28x faster | Significant (t=95.93)  |
| scimark_monte_carlo        | 58.4 ms  | 45.6 ms  | 1.28x faster | Significant (t=68.49)  |
| scimark_lu                 | 95.6 ms  | 75.2 ms  | 1.27x faster | Significant (t=135.71) |
| chaos                      | 63.3 ms  | 49.7 ms  | 1.27x faster | Significant (t=106.80) |
| crypto_pyaes               | 66.9 ms  | 53.3 ms  | 1.26x faster | Significant (t=140.99) |
| unpickle                   | 12.3 us  | 9.84 us  | 1.25x faster | Significant (t=132.77) |
| scimark_sor                |  100 ms  | 80.9 ms  | 1.24x faster | Significant (t=82.80)  |
| json_dumps                 | 10.6 ms  | 8.52 ms  | 1.24x faster | Significant (t=142.79) |
| nqueens                    | 76.7 ms  | 62.6 ms  | 1.23x faster | Significant (t=145.79) |
| meteor_contest             | 91.4 ms  | 74.9 ms  | 1.22x faster | Significant (t=255.50) |
| raytrace                   |  268 ms  |  221 ms  | 1.21x faster | Significant (t=96.15)  |
| float                      | 65.9 ms  | 54.6 ms  | 1.21x faster | Significant (t=66.94)  |
| async_generators           |  289 ms  |  240 ms  | 1.21x faster | Significant (t=113.46) |
| deepcopy_reduce            | 2.80 us  | 2.33 us  | 1.20x faster | Significant (t=77.43)  |
| xml_etree_parse            |  137 ms  |  114 ms  | 1.20x faster | Significant (t=63.43)  |
| fannkuch                   |  299 ms  |  248 ms  | 1.20x faster | Significant (t=51.63)  |
| mdp                        | 2.29 sec | 1.91 sec | 1.20x faster | Significant (t=36.58)  |
| pickle_pure_python         |  277 us  |  233 us  | 1.19x faster | Significant (t=96.70)  |
| hexiom                     | 5.59 ms  | 4.70 ms  | 1.19x faster | Significant (t=73.97)  |
| nbody                      | 86.0 ms  | 72.0 ms  | 1.19x faster | Significant (t=66.70)  |
| sympy_expand               |  427 ms  |  360 ms  | 1.19x faster | Significant (t=140.20) |
| regex_compile              |  120 ms  |  101 ms  | 1.19x faster | Significant (t=122.47) |
| genshi_xml                 | 45.2 ms  | 38.4 ms  | 1.18x faster | Significant (t=98.82)  |
| tomli_loads                | 1.88 sec | 1.58 sec | 1.18x faster | Significant (t=98.12)  |
| deepcopy_memo              | 31.7 us  | 27.0 us  | 1.17x faster | Significant (t=49.49)  |
| unpickle_pure_python       |  204 us  |  174 us  | 1.17x faster | Significant (t=43.66)  |
| sqlglot_optimize           | 46.3 ms  | 39.5 ms  | 1.17x faster | Significant (t=133.88) |
| sympy_str                  |  258 ms  |  221 ms  | 1.17x faster | Significant (t=118.02) |
| sqlglot_normalize          |  248 ms  |  212 ms  | 1.17x faster | Significant (t=111.14) |
| comprehensions             | 19.5 us  | 16.9 us  | 1.16x faster | Significant (t=92.03)  |
| sqlglot_parse              | 1.26 ms  | 1.08 ms  | 1.16x faster | Significant (t=91.52)  |
| async_tree_cpu_io_mixed_tg |  670 ms  |  580 ms  | 1.16x faster | Significant (t=45.20)  |
| xml_etree_generate         | 64.9 ms  | 56.1 ms  | 1.16x faster | Significant (t=115.82) |
| sympy_sum                  |  143 ms  |  124 ms  | 1.16x faster | Significant (t=105.37) |
| regex_dna                  |  143 ms  |  123 ms  | 1.16x faster | Significant (t=102.23) |
| sqlglot_transpile          | 1.50 ms  | 1.30 ms  | 1.15x faster | Significant (t=87.25)  |
| richards_super             | 49.9 ms  | 43.3 ms  | 1.15x faster | Significant (t=55.70)  |
| async_tree_cpu_io_mixed    |  728 ms  |  635 ms  | 1.15x faster | Significant (t=47.16)  |
| django_template            | 30.6 ms  | 26.5 ms  | 1.15x faster | Significant (t=37.09)  |
| async_tree_memoization_tg  |  565 ms  |  492 ms  | 1.15x faster | Significant (t=25.74)  |
| richards                   | 39.4 ms  | 34.3 ms  | 1.15x faster | Significant (t=24.63)  |
| sqlite_synth               | 2.23 us  | 1.95 us  | 1.14x faster | Significant (t=89.87)  |
| deltablue                  | 3.23 ms  | 2.84 ms  | 1.14x faster | Significant (t=69.52)  |
| pyflate                    |  357 ms  |  312 ms  | 1.14x faster | Significant (t=69.35)  |
| tornado_http               |  107 ms  | 94.0 ms  | 1.14x faster | Significant (t=48.73)  |
| coroutines                 | 23.1 ms  | 20.3 ms  | 1.14x faster | Significant (t=24.88)  |
| sympy_integrate            | 18.0 ms  | 15.8 ms  | 1.14x faster | Significant (t=127.30) |
| 2to3                       |  232 ms  |  203 ms  | 1.14x faster | Significant (t=114.23) |
| deepcopy                   |  384 us  |  340 us  | 1.13x faster | Significant (t=90.06)  |
| pprint_pformat             | 1.27 sec | 1.13 sec | 1.13x faster | Significant (t=72.54)  |
| pprint_safe_repr           |  617 ms  |  546 ms  | 1.13x faster | Significant (t=68.58)  |
| pathlib                    | 14.0 ms  | 12.4 ms  | 1.13x faster | Significant (t=117.08) |
| async_tree_none_tg         |  416 ms  |  371 ms  | 1.12x faster | Significant (t=74.94)  |
| sqlalchemy_imperative      | 17.0 ms  | 15.2 ms  | 1.12x faster | Significant (t=62.68)  |
| genshi_text                | 19.4 ms  | 17.4 ms  | 1.12x faster | Significant (t=60.45)  |
| async_tree_none            |  506 ms  |  450 ms  | 1.12x faster | Significant (t=49.63)  |
| docutils                   | 2.21 sec | 1.98 sec | 1.12x faster | Significant (t=36.33)  |
| unpack_sequence            | 33.8 ns  | 30.3 ns  | 1.12x faster | Significant (t=14.87)  |
| logging_format             | 8.41 us  | 7.59 us  | 1.11x faster | Significant (t=68.63)  |
| go                         |  123 ms  |  112 ms  | 1.11x faster | Significant (t=63.17)  |
| xml_etree_process          | 46.1 ms  | 41.5 ms  | 1.11x faster | Significant (t=46.02)  |
| html5lib                   | 59.9 ms  | 53.8 ms  | 1.11x faster | Significant (t=22.40)  |
| dulwich_log                | 62.5 ms  | 56.7 ms  | 1.10x faster | Significant (t=57.28)  |
| sqlalchemy_declarative     |  106 ms  | 96.1 ms  | 1.10x faster | Significant (t=35.14)  |
| python_startup_no_site     | 4.89 ms  | 4.45 ms  | 1.10x faster | Significant (t=251.25) |
| pidigits                   |  152 ms  |  138 ms  | 1.10x faster | Significant (t=145.12) |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                |  782 ms  |  968 ms  | 1.24x slower | Significant (t=-83.67) |
| asyncio_tcp_ssl            | 1.95 sec | 2.16 sec | 1.11x slower | Significant (t=-26.79) |
| bench_mp_pool              | 28.9 ms  | 30.9 ms  | 1.07x slower | Significant (t=-6.65)  |
| dask                       |  452 ms  |  461 ms  | 1.02x slower | Not significant        |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
