# Python 3.11.3 benchmarks

Date: 13.04.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), commit 9c58774e

## Subjects

- official Docker image: docker.io/library/python:3.11.3-slim-bullseye
- Debian package `python3.11=3.11.3` (lands in "experimental" as of 13.04.2023)
- own [package](https://github.com/rockdrilla/debian-container/tree/main/package/python)/image: docker.io/rockdrilla/python:3.11.3-bullseye

## Prerequisites

- install Debian package `build-essential` in order to build python packages:

  ```sh
  sudo apt-get update && sudo apt-get install -y build-essential
  ```

- install `pyperformance` directly from GitHub:

  ```sh
  pip install https://github.com/python/pyperformance/archive/9c58774e.tar.gz
  ```

NB: Debian requires `--break-system-packages` flag to be passed for `pip install`.

- run `pyperformance`:

  ```sh
  pyperformance run --rigorous
  ```

## Results

Table legend:

`Subj1` - official Docker image

`Subj2` - Debian package

`Subj3` - own package/image

### official Docker image versus Debian package

```text
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark               | Subj1    | Subj2    | Change       | Significance           |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| telco                   | 6.87 ms  | 4.91 ms  | 1.40x faster | Significant (t=118.69) |
| scimark_fft             |  288 ms  |  212 ms  | 1.36x faster | Significant (t=90.75)  |
| scimark_sparse_mat_mult | 4.17 ms  | 3.12 ms  | 1.33x faster | Significant (t=63.45)  |
| json_dumps              | 11.9 ms  | 9.23 ms  | 1.29x faster | Significant (t=148.52) |
| spectral_norm           | 93.2 ms  | 73.6 ms  | 1.27x faster | Significant (t=132.46) |
| regex_effbot            | 2.95 ms  | 2.36 ms  | 1.25x faster | Significant (t=103.17) |
| scimark_monte_carlo     | 60.2 ms  | 50.2 ms  | 1.20x faster | Significant (t=91.49)  |
| regex_dna               |  158 ms  |  132 ms  | 1.20x faster | Significant (t=69.44)  |
| pidigits                |  176 ms  |  147 ms  | 1.20x faster | Significant (t=6.31)   |
| chaos                   | 63.2 ms  | 52.7 ms  | 1.20x faster | Significant (t=52.50)  |
| generators              | 49.2 ms  | 41.1 ms  | 1.20x faster | Significant (t=48.69)  |
| docutils                | 2.62 sec | 2.19 sec | 1.20x faster | Significant (t=27.03)  |
| crypto_pyaes            | 67.6 ms  | 56.6 ms  | 1.19x faster | Significant (t=89.46)  |
| python_startup          | 8.26 ms  | 6.95 ms  | 1.19x faster | Significant (t=53.65)  |
| nbody                   | 85.0 ms  | 71.6 ms  | 1.19x faster | Significant (t=49.65)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp             |  834 ms  | 1.04 sec | 1.25x slower | Significant (t=-41.78) |
| async_tree_memoization  |  643 ms  |  678 ms  | 1.05x slower | Significant (t=-9.73)  |
| async_tree_none         |  526 ms  |  553 ms  | 1.05x slower | Significant (t=-8.29)  |
| coroutines              | 20.9 ms  | 21.8 ms  | 1.04x slower | Significant (t=-11.82) |
| async_tree_cpu_io_mixed |  744 ms  |  765 ms  | 1.03x slower | Significant (t=-3.42)  |
| bench_mp_pool           | 5.64 ms  | 5.83 ms  | 1.03x slower | Significant (t=-2.41)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
```

### Debian package versus own package/image

```text
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark               | Subj2    | Subj3    | Change       | Significance           |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| mdp                     | 2.62 sec | 2.03 sec | 1.29x faster | Significant (t=27.70)  |
| async_generators        |  274 ms  |  219 ms  | 1.25x faster | Significant (t=64.79)  |
| scimark_sparse_mat_mult | 3.12 ms  | 2.55 ms  | 1.23x faster | Significant (t=31.14)  |
| fannkuch                |  304 ms  |  256 ms  | 1.19x faster | Significant (t=7.82)   |
| scimark_fft             |  212 ms  |  178 ms  | 1.19x faster | Significant (t=37.12)  |
| coroutines              | 21.8 ms  | 18.4 ms  | 1.18x faster | Significant (t=30.60)  |
| gc_traversal            | 2.47 ms  | 2.10 ms  | 1.17x faster | Significant (t=12.24)  |
| generators              | 41.1 ms  | 36.2 ms  | 1.13x faster | Significant (t=18.02)  |
| async_tree_none         |  553 ms  |  495 ms  | 1.12x faster | Significant (t=18.28)  |
| async_tree_cpu_io_mixed |  765 ms  |  690 ms  | 1.11x faster | Significant (t=13.15)  |
| scimark_lu              | 83.5 ms  | 76.5 ms  | 1.09x faster | Significant (t=32.39)  |
| html5lib                | 57.6 ms  | 53.6 ms  | 1.08x faster | Significant (t=8.42)   |
| deltablue               | 3.08 ms  | 2.85 ms  | 1.08x faster | Significant (t=35.99)  |
| scimark_sor             | 89.8 ms  | 83.5 ms  | 1.08x faster | Significant (t=29.18)  |
| go                      |  122 ms  |  113 ms  | 1.08x faster | Significant (t=22.79)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| python_startup_no_site  | 5.00 ms  | 6.09 ms  | 1.22x slower | Significant (t=-50.48) |
| python_startup          | 6.95 ms  | 8.40 ms  | 1.21x slower | Significant (t=-52.29) |
| bench_mp_pool           | 5.83 ms  | 6.86 ms  | 1.18x slower | Significant (t=-9.98)  |
| tornado_http            |  108 ms  |  118 ms  | 1.09x slower | Significant (t=-10.97) |
| docutils                | 2.19 sec | 2.31 sec | 1.05x slower | Significant (t=-5.92)  |
| regex_v8                | 16.9 ms  | 17.7 ms  | 1.04x slower | Significant (t=-13.01) |
| json_dumps              | 9.23 ms  | 9.48 ms  | 1.03x slower | Significant (t=-9.64)  |
| chaos                   | 52.7 ms  | 54.5 ms  | 1.03x slower | Significant (t=-8.45)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
```

### official Docker image versus own package/image

```text
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark               | Subj1    | Subj3    | Change       | Significance           |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| scimark_sparse_mat_mult | 4.17 ms  | 2.55 ms  | 1.64x faster | Significant (t=99.78)  |
| scimark_fft             |  288 ms  |  178 ms  | 1.62x faster | Significant (t=178.75) |
| telco                   | 6.87 ms  | 4.65 ms  | 1.48x faster | Significant (t=78.97)  |
| generators              | 49.2 ms  | 36.2 ms  | 1.36x faster | Significant (t=47.55)  |
| mdp                     | 2.73 sec | 2.03 sec | 1.35x faster | Significant (t=33.76)  |
| spectral_norm           | 93.2 ms  | 69.7 ms  | 1.34x faster | Significant (t=127.11) |
| async_generators        |  285 ms  |  219 ms  | 1.30x faster | Significant (t=102.08) |
| gc_traversal            | 2.72 ms  | 2.10 ms  | 1.29x faster | Significant (t=21.20)  |
| scimark_monte_carlo     | 60.2 ms  | 47.1 ms  | 1.28x faster | Significant (t=92.07)  |
| nbody                   | 85.0 ms  | 66.9 ms  | 1.27x faster | Significant (t=60.68)  |
| json_dumps              | 11.9 ms  | 9.48 ms  | 1.26x faster | Significant (t=101.22) |
| regex_effbot            | 2.95 ms  | 2.37 ms  | 1.24x faster | Significant (t=83.52)  |
| meteor_contest          | 94.0 ms  | 76.5 ms  | 1.23x faster | Significant (t=77.93)  |
| tomli_loads             | 1.99 sec | 1.62 sec | 1.23x faster | Significant (t=33.98)  |
| crypto_pyaes            | 67.6 ms  | 55.5 ms  | 1.22x faster | Significant (t=86.36)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp             |  834 ms  | 1.04 sec | 1.25x slower | Significant (t=-47.92) |
| bench_mp_pool           | 5.64 ms  | 6.86 ms  | 1.22x slower | Significant (t=-12.41) |
| python_startup_no_site  | 5.97 ms  | 6.09 ms  | 1.02x slower | Significant (t=-6.24)  |
| ----------------------- | -------- | -------- | ------------ | ---------------------- |
```


### raw results

```text
| ----------------------- | ------------------- | ------------------- | ------------------- |
| benchmark name          | Subj1               | Subj2               | Subj3               |
|                         | ------------------- | ------------------- | ------------------- |
|                         | mean     | std dev  | mean     | std dev  | mean     | std dev  |
| ----------------------- | ------------------- | ------------------- | ------------------- |
| 2to3                    |  241 ms  |    5 ms  |  240 ms  |   12 ms  |  233 ms  |    5 ms  |
| async_generators        |  285 ms  |    4 ms  |  274 ms  |    7 ms  |  219 ms  |    6 ms  |
| async_tree_none         |  526 ms  |   17 ms  |  553 ms  |   31 ms  |  495 ms  |   16 ms  |
| async_tree_cpu_io_mixed |  744 ms  |   29 ms  |  765 ms  |   59 ms  |  690 ms  |   21 ms  |
| async_tree_io           | 1.26 sec | 0.04 sec | 1.24 sec | 0.05 sec | 1.16 sec | 0.04 sec |
| async_tree_memoization  |  643 ms  |   26 ms  |  678 ms  |   30 ms  |  628 ms  |   25 ms  |
| asyncio_tcp             |  834 ms  |   39 ms  | 1.04 sec | 0.04 sec | 1.04 sec | 0.03 sec |
| chameleon               | 5.87 ms  | 0.09 ms  | 5.42 ms  | 0.15 ms  | 5.36 ms  | 0.14 ms  |
| chaos                   | 63.2 ms  |  1.8 ms  | 52.7 ms  |  1.3 ms  | 54.5 ms  |  1.8 ms  |
| comprehensions          | 19.6 us  |  0.5 us  | 17.8 us  |  0.3 us  | 17.0 us  |  0.5 us  |
| bench_mp_pool           | 5.64 ms  | 0.56 ms  | 5.83 ms  | 0.66 ms  | 6.86 ms  | 0.93 ms  |
| bench_thread_pool       | 1.28 ms  | 0.03 ms  | 1.22 ms  | 0.02 ms  | 1.21 ms  | 0.01 ms  |
| coroutines              | 20.9 ms  |  0.4 ms  | 21.8 ms  |  0.7 ms  | 18.4 ms  |  1.0 ms  |
| coverage                | 63.0 ms  |  1.2 ms  | 55.1 ms  |  1.1 ms  | 53.2 ms  |  1.2 ms  |
| crypto_pyaes            | 67.6 ms  |  1.0 ms  | 56.6 ms  |  1.0 ms  | 55.5 ms  |  1.2 ms  |
| dask                    |  423 ms  |   16 ms  |  400 ms  |   13 ms  |  396 ms  |   13 ms  |
| deepcopy                |  381 us  |    5 us  |  362 us  |    6 us  |  346 us  |   12 us  |
| deepcopy_reduce         | 2.78 us  | 0.13 us  | 2.60 us  | 0.06 us  | 2.43 us  | 0.05 us  |
| deepcopy_memo           | 30.5 us  |  2.8 us  | 29.0 us  |  0.5 us  | 27.7 us  |  0.6 us  |
| deltablue               | 3.27 ms  | 0.24 ms  | 3.08 ms  | 0.03 ms  | 2.85 ms  | 0.06 ms  |
| django_template         | 32.0 ms  |  1.1 ms  | 28.0 ms  |  0.5 ms  | 27.9 ms  |  2.3 ms  |
| docutils                | 2.62 sec | 0.15 sec | 2.19 sec | 0.09 sec | 2.31 sec | 0.20 sec |
| dulwich_log             | 65.6 ms  |  1.2 ms  | 61.1 ms  |  1.5 ms  | 58.6 ms  |  1.8 ms  |
| fannkuch                |  310 ms  |   10 ms  |  304 ms  |   66 ms  |  256 ms  |   12 ms  |
| float                   | 68.5 ms  |  1.1 ms  | 58.0 ms  |  1.3 ms  | 56.2 ms  |  1.3 ms  |
| create_gc_cycles        |  894 us  |   15 us  |  853 us  |   10 us  |  833 us  |   26 us  |
| gc_traversal            | 2.72 ms  | 0.15 ms  | 2.47 ms  | 0.17 ms  | 2.10 ms  | 0.28 ms  |
| generators              | 49.2 ms  |  1.3 ms  | 41.1 ms  |  1.3 ms  | 36.2 ms  |  2.7 ms  |
| genshi_text             | 20.2 ms  |  0.3 ms  | 18.4 ms  |  0.3 ms  | 18.1 ms  |  0.5 ms  |
| genshi_xml              | 46.7 ms  |  1.0 ms  | 41.5 ms  |  0.7 ms  | 41.5 ms  |  1.7 ms  |
| go                      |  128 ms  |    3 ms  |  122 ms  |    3 ms  |  113 ms  |    3 ms  |
| hexiom                  | 5.60 ms  | 0.09 ms  | 5.10 ms  | 0.07 ms  | 4.82 ms  | 0.15 ms  |
| html5lib                | 62.7 ms  |  5.5 ms  | 57.6 ms  |  3.3 ms  | 53.6 ms  |  4.1 ms  |
| json_dumps              | 11.9 ms  |  0.1 ms  | 9.23 ms  | 0.16 ms  | 9.48 ms  | 0.24 ms  |
| json_loads              | 25.5 us  |  0.5 us  | 16.5 us  |  0.2 us  | 18.0 us  |  0.8 us  |
| logging_format          | 8.43 us  | 0.19 us  | 7.88 us  | 0.11 us  | 7.56 us  | 0.15 us  |
| logging_silent          | 85.2 ns  |  3.2 ns  | 84.0 ns  |  1.8 ns  | 81.3 ns  |  2.8 ns  |
| logging_simple          | 7.49 us  | 0.28 us  | 7.34 us  | 0.20 us  | 7.08 us  | 0.13 us  |
| mako                    | 9.07 ms  | 0.20 ms  | 8.12 ms  | 0.15 ms  | 7.60 ms  | 0.21 ms  |
| mdp                     | 2.73 sec | 0.15 sec | 2.62 sec | 0.16 sec | 2.03 sec | 0.17 sec |
| meteor_contest          | 94.0 ms  |  1.6 ms  | 79.5 ms  |  1.5 ms  | 76.5 ms  |  1.9 ms  |
| nbody                   | 85.0 ms  |  2.6 ms  | 71.6 ms  |  1.5 ms  | 66.9 ms  |  2.0 ms  |
| nqueens                 | 77.4 ms  |  2.2 ms  | 66.9 ms  |  1.8 ms  | 65.5 ms  |  2.7 ms  |
| pathlib                 | 14.8 ms  |  0.3 ms  | 14.1 ms  |  0.4 ms  | 13.1 ms  |  0.6 ms  |
| pickle                  | 11.5 us  |  1.2 us  | 6.90 us  | 0.11 us  | 8.16 us  | 0.21 us  |
| pickle_dict             | 27.0 us  |  3.0 us  | 17.6 us  |  1.2 us  | 19.4 us  |  0.4 us  |
| pickle_list             | 3.90 us  | 0.06 us  | 2.09 us  | 0.10 us  | 2.74 us  | 0.09 us  |
| pickle_pure_python      |  289 us  |    6 us  |  239 us  |    4 us  |  232 us  |    6 us  |
| pidigits                |  176 ms  |   51 ms  |  147 ms  |    1 ms  |  144 ms  |    2 ms  |
| pprint_safe_repr        |  631 ms  |   13 ms  |  586 ms  |   12 ms  |  552 ms  |   12 ms  |
| pprint_pformat          | 1.31 sec | 0.02 sec | 1.21 sec | 0.02 sec | 1.15 sec | 0.03 sec |
| pyflate                 |  372 ms  |   13 ms  |  355 ms  |   17 ms  |  333 ms  |    9 ms  |
| python_startup          | 8.26 ms  | 0.24 ms  | 6.95 ms  | 0.43 ms  | 8.40 ms  | 0.35 ms  |
| python_startup_no_site  | 5.97 ms  | 0.09 ms  | 5.00 ms  | 0.16 ms  | 6.09 ms  | 0.40 ms  |
| raytrace                |  277 ms  |    6 ms  |  237 ms  |    4 ms  |  230 ms  |    4 ms  |
| regex_compile           |  124 ms  |    2 ms  |  112 ms  |    2 ms  |  107 ms  |    3 ms  |
| regex_dna               |  158 ms  |    3 ms  |  132 ms  |    3 ms  |  132 ms  |    3 ms  |
| regex_effbot            | 2.95 ms  | 0.05 ms  | 2.36 ms  | 0.03 ms  | 2.37 ms  | 0.05 ms  |
| regex_v8                | 19.8 ms  |  0.3 ms  | 16.9 ms  |  0.4 ms  | 17.7 ms  |  0.5 ms  |
| richards                | 39.1 ms  |  1.3 ms  | 39.1 ms  |  1.4 ms  | 36.4 ms  |  1.2 ms  |
| scimark_fft             |  288 ms  |    4 ms  |  212 ms  |    8 ms  |  178 ms  |    5 ms  |
| scimark_lu              | 92.2 ms  |  2.2 ms  | 83.5 ms  |  1.3 ms  | 76.5 ms  |  2.0 ms  |
| scimark_monte_carlo     | 60.2 ms  |  0.8 ms  | 50.2 ms  |  0.9 ms  | 47.1 ms  |  1.3 ms  |
| scimark_sor             | 98.0 ms  |  5.7 ms  | 89.8 ms  |  1.2 ms  | 83.5 ms  |  2.1 ms  |
| scimark_sparse_mat_mult | 4.17 ms  | 0.11 ms  | 3.12 ms  | 0.14 ms  | 2.55 ms  | 0.14 ms  |
| spectral_norm           | 93.2 ms  |  1.4 ms  | 73.6 ms  |  0.9 ms  | 69.7 ms  |  1.5 ms  |
| sqlalchemy_declarative  |  113 ms  |    5 ms  |  107 ms  |    5 ms  |  104 ms  |    3 ms  |
| sqlalchemy_imperative   | 17.2 ms  |  0.3 ms  | 16.6 ms  |  0.3 ms  | 15.4 ms  |  0.5 ms  |
| sqlglot_parse           | 1.31 ms  | 0.04 ms  | 1.17 ms  | 0.02 ms  | 1.14 ms  | 0.04 ms  |
| sqlglot_transpile       | 1.65 ms  | 0.11 ms  | 1.39 ms  | 0.03 ms  | 1.39 ms  | 0.09 ms  |
| sqlglot_optimize        | 48.6 ms  |  0.8 ms  | 42.3 ms  |  0.6 ms  | 41.1 ms  |  0.9 ms  |
| sqlglot_normalize       |  259 ms  |    4 ms  |  223 ms  |    4 ms  |  220 ms  |    6 ms  |
| sqlite_synth            | 2.23 us  | 0.04 us  | 2.00 us  | 0.03 us  | 1.95 us  | 0.08 us  |
| sympy_expand            |  437 ms  |    5 ms  |  384 ms  |    4 ms  |  391 ms  |   47 ms  |
| sympy_integrate         | 18.7 ms  |  0.3 ms  | 17.6 ms  |  0.9 ms  | 17.2 ms  |  0.9 ms  |
| sympy_sum               |  150 ms  |    2 ms  |  134 ms  |    2 ms  |  136 ms  |    5 ms  |
| sympy_str               |  268 ms  |    4 ms  |  238 ms  |    4 ms  |  238 ms  |    8 ms  |
| telco                   | 6.87 ms  | 0.17 ms  | 4.91 ms  | 0.07 ms  | 4.65 ms  | 0.26 ms  |
| tomli_loads             | 1.99 sec | 0.09 sec | 1.71 sec | 0.03 sec | 1.62 sec | 0.08 sec |
| tornado_http            |  120 ms  |    4 ms  |  108 ms  |    6 ms  |  118 ms  |    8 ms  |
| unpack_sequence         | 39.5 ns  |  1.5 ns  | 31.4 ns  |  0.7 ns  | 31.2 ns  |  1.0 ns  |
| unpickle                | 12.8 us  |  0.3 us  | 9.75 us  | 0.20 us  | 10.9 us  |  0.4 us  |
| unpickle_list           | 4.54 us  | 0.10 us  | 3.22 us  | 0.08 us  | 3.15 us  | 0.16 us  |
| unpickle_pure_python    |  213 us  |    2 us  |  190 us  |    9 us  |  203 us  |   40 us  |
| xml_etree_parse         |  138 ms  |    3 ms  |  131 ms  |   10 ms  |  129 ms  |   12 ms  |
| xml_etree_iterparse     | 90.6 ms  |  3.8 ms  | 81.6 ms  |  9.5 ms  | 81.9 ms  |  8.3 ms  |
| xml_etree_generate      | 68.8 ms  |  0.8 ms  | 60.3 ms  |  2.0 ms  | 56.6 ms  |  2.4 ms  |
| xml_etree_process       | 48.7 ms  |  0.8 ms  | 44.7 ms  |  2.7 ms  | 42.9 ms  |  1.5 ms  |
| ----------------------- | ------------------- | ------------------- | ------------------- |
```
