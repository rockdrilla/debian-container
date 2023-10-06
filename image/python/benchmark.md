# Python 3.11.6 benchmarks

Date: 06.10.2023

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
  pip install https://github.com/python/pyperformance/archive/ef1d636b.tar.gz
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
| scimark_sparse_mat_mult    | 4.14 ms  | 2.40 ms  | 1.73x faster | Significant (t=96.39)  |
| pickle                     | 11.1 us  | 7.10 us  | 1.57x faster | Significant (t=417.19) |
| pickle_list                | 4.00 us  | 2.55 us  | 1.57x faster | Significant (t=193.87) |
| scimark_fft                |  268 ms  |  174 ms  | 1.54x faster | Significant (t=186.58) |
| typing_runtime_protocols   |  543 us  |  354 us  | 1.53x faster | Significant (t=215.94) |
| json_loads                 | 25.2 us  | 16.6 us  | 1.52x faster | Significant (t=326.50) |
| pickle_dict                | 27.5 us  | 18.8 us  | 1.46x faster | Significant (t=530.86) |
| spectral_norm              | 93.1 ms  | 66.5 ms  | 1.40x faster | Significant (t=131.86) |
| telco                      | 6.55 ms  | 4.73 ms  | 1.38x faster | Significant (t=170.17) |
| nbody                      | 87.6 ms  | 64.9 ms  | 1.35x faster | Significant (t=31.31)  |
| async_generators           |  287 ms  |  213 ms  | 1.35x faster | Significant (t=109.74) |
| crypto_pyaes               | 67.6 ms  | 51.2 ms  | 1.32x faster | Significant (t=191.82) |
| chaos                      | 63.7 ms  | 48.8 ms  | 1.31x faster | Significant (t=94.95)  |
| unpickle_list              | 4.56 us  | 3.51 us  | 1.30x faster | Significant (t=77.30)  |
| generators                 | 47.2 ms  | 36.7 ms  | 1.29x faster | Significant (t=99.97)  |
| coverage                   | 66.1 ms  | 51.7 ms  | 1.28x faster | Significant (t=92.30)  |
| meteor_contest             | 90.5 ms  | 70.6 ms  | 1.28x faster | Significant (t=225.47) |
| xml_etree_iterparse        | 90.6 ms  | 70.9 ms  | 1.28x faster | Significant (t=162.56) |
| fannkuch                   |  314 ms  |  247 ms  | 1.27x faster | Significant (t=59.08)  |
| mdp                        | 2.37 sec | 1.87 sec | 1.27x faster | Significant (t=54.87)  |
| scimark_monte_carlo        | 58.9 ms  | 46.2 ms  | 1.27x faster | Significant (t=151.63) |
| float                      | 67.6 ms  | 53.5 ms  | 1.26x faster | Significant (t=97.52)  |
| unpickle                   | 12.1 us  | 9.67 us  | 1.25x faster | Significant (t=83.16)  |
| scimark_lu                 | 94.4 ms  | 75.4 ms  | 1.25x faster | Significant (t=80.66)  |
| nqueens                    | 78.4 ms  | 62.7 ms  | 1.25x faster | Significant (t=47.01)  |
| pickle_pure_python         |  272 us  |  219 us  | 1.24x faster | Significant (t=136.79) |
| tomli_loads                | 1.90 sec | 1.55 sec | 1.23x faster | Significant (t=127.23) |
| raytrace                   |  273 ms  |  223 ms  | 1.22x faster | Significant (t=84.21)  |
| hexiom                     | 5.71 ms  | 4.69 ms  | 1.22x faster | Significant (t=56.18)  |
| sqlglot_normalize          |  250 ms  |  206 ms  | 1.22x faster | Significant (t=145.47) |
| scimark_sor                | 98.9 ms  | 81.4 ms  | 1.21x faster | Significant (t=47.74)  |
| sqlglot_optimize           | 46.4 ms  | 38.2 ms  | 1.21x faster | Significant (t=199.20) |
| xml_etree_parse            |  137 ms  |  115 ms  | 1.19x faster | Significant (t=99.17)  |
| sqlglot_parse              | 1.24 ms  | 1.05 ms  | 1.18x faster | Significant (t=92.58)  |
| unpack_sequence            | 35.1 ns  | 29.8 ns  | 1.18x faster | Significant (t=28.05)  |
| json_dumps                 | 10.3 ms  | 8.77 ms  | 1.18x faster | Significant (t=156.30) |
| pathlib                    | 14.4 ms  | 12.2 ms  | 1.18x faster | Significant (t=122.19) |
| regex_effbot               | 2.63 ms  | 2.23 ms  | 1.18x faster | Significant (t=115.24) |
| django_template            | 30.2 ms  | 25.7 ms  | 1.17x faster | Significant (t=96.75)  |
| async_tree_cpu_io_mixed_tg |  666 ms  |  570 ms  | 1.17x faster | Significant (t=60.50)  |
| xml_etree_generate         | 64.7 ms  | 55.5 ms  | 1.17x faster | Significant (t=46.52)  |
| deepcopy_memo              | 31.5 us  | 26.9 us  | 1.17x faster | Significant (t=30.63)  |
| sympy_str                  |  250 ms  |  213 ms  | 1.17x faster | Significant (t=135.62) |
| sympy_sum                  |  141 ms  |  120 ms  | 1.17x faster | Significant (t=129.51) |
| sympy_expand               |  410 ms  |  349 ms  | 1.17x faster | Significant (t=124.40) |
| sqlglot_transpile          | 1.48 ms  | 1.26 ms  | 1.17x faster | Significant (t=102.73) |
| comprehensions             | 19.7 us  | 17.0 us  | 1.16x faster | Significant (t=83.80)  |
| deepcopy_reduce            | 2.77 us  | 2.38 us  | 1.16x faster | Significant (t=67.94)  |
| regex_dna                  |  147 ms  |  127 ms  | 1.16x faster | Significant (t=64.13)  |
| genshi_xml                 | 44.3 ms  | 38.4 ms  | 1.15x faster | Significant (t=80.14)  |
| sympy_integrate            | 17.7 ms  | 15.3 ms  | 1.15x faster | Significant (t=170.17) |
| unpickle_pure_python       |  203 us  |  178 us  | 1.14x faster | Significant (t=98.41)  |
| sqlalchemy_imperative      | 16.8 ms  | 14.7 ms  | 1.14x faster | Significant (t=77.19)  |
| docutils                   | 2.20 sec | 1.93 sec | 1.14x faster | Significant (t=64.75)  |
| async_tree_memoization_tg  |  561 ms  |  490 ms  | 1.14x faster | Significant (t=25.03)  |
| xml_etree_process          | 45.5 ms  | 39.8 ms  | 1.14x faster | Significant (t=122.02) |
| logging_format             | 8.31 us  | 7.31 us  | 1.14x faster | Significant (t=119.79) |
| async_tree_none_tg         |  417 ms  |  368 ms  | 1.13x faster | Significant (t=98.55)  |
| pprint_pformat             | 1.26 sec | 1.11 sec | 1.13x faster | Significant (t=83.71)  |
| 2to3                       |  233 ms  |  206 ms  | 1.13x faster | Significant (t=76.82)  |
| deepcopy                   |  381 us  |  338 us  | 1.13x faster | Significant (t=65.15)  |
| dulwich_log                | 62.8 ms  | 55.7 ms  | 1.13x faster | Significant (t=63.51)  |
| pprint_safe_repr           |  609 ms  |  538 ms  | 1.13x faster | Significant (t=60.44)  |
| tornado_http               |  104 ms  | 91.9 ms  | 1.13x faster | Significant (t=48.02)  |
| async_tree_io_tg           | 1.13 sec | 1.00 sec | 1.13x faster | Significant (t=108.24) |
| regex_compile              |  116 ms  |  103 ms  | 1.13x faster | Significant (t=101.86) |
| sqlite_synth               | 2.15 us  | 1.91 us  | 1.12x faster | Significant (t=92.33)  |
| deltablue                  | 3.17 ms  | 2.84 ms  | 1.12x faster | Significant (t=84.81)  |
| async_tree_none            |  505 ms  |  450 ms  | 1.12x faster | Significant (t=45.02)  |
| sqlalchemy_declarative     |  105 ms  | 93.1 ms  | 1.12x faster | Significant (t=36.00)  |
| async_tree_cpu_io_mixed    |  725 ms  |  646 ms  | 1.12x faster | Significant (t=24.07)  |
| logging_simple             | 7.70 us  | 6.85 us  | 1.12x faster | Significant (t=116.14) |
| richards_super             | 48.7 ms  | 43.7 ms  | 1.11x faster | Significant (t=40.87)  |
| coroutines                 | 21.9 ms  | 19.8 ms  | 1.11x faster | Significant (t=34.71)  |
| gc_traversal               | 2.60 ms  | 2.34 ms  | 1.11x faster | Significant (t=13.73)  |
| go                         |  121 ms  |  110 ms  | 1.10x faster | Significant (t=59.91)  |
| richards                   | 38.6 ms  | 35.2 ms  | 1.10x faster | Significant (t=32.67)  |
| mako                       | 8.02 ms  | 7.31 ms  | 1.10x faster | Significant (t=31.70)  |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                |  769 ms  | 1.00 sec | 1.30x slower | Significant (t=-70.24) |
| asyncio_tcp_ssl            | 1.95 sec | 2.02 sec | 1.04x slower | Significant (t=-15.63) |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
