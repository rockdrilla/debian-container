# Python 3.11.3 benchmarks

Date: 05.06.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), commit 3054f7bb

## Subjects

- official Docker image: docker.io/library/python:3.11.3-slim-bullseye
- Debian package `python3.11=3.11.3` (lands in "experimental" as of 05.06.2023)
- own [package](https://github.com/rockdrilla/debian-container/tree/main/package/python)/image: docker.io/rockdrilla/python:3.11.3-bullseye

## Prerequisites

- install Debian package `build-essential` in order to build Python packages:

  ```sh
  apt update && apt upgrade -y && apt install -y build-essential && apt clean
  ```

- pure Debian's Python: install Debian packages `python3-dev` and `python3-pip` in order to install and build Python packages:

  ```sh
  apt update && apt install -y python3-dev python3-pip && apt clean
  ```

- pure Debian's Python: use `experimental` channel for (most) Python-related packages:

  ```sh
  echo 'deb http://deb.debian.org/debian experimental main' > /etc/apt/sources.list.d/experimental.list
  cat > /etc/apt/preferences.d/python <<-'EOF'
  Package: src:python*
  Pin: release a=experimental
  Pin-Priority: 600
  EOF
  apt update && apt upgrade -y && apt clean
  ```

- install `pyperformance` directly from GitHub:

  ```sh
  pip install https://github.com/python/pyperformance/archive/3054f7bb.tar.gz
  ```

NB: Debian requires `--break-system-packages` flag to be passed for `pip install`.

- run `pyperformance`:

  ```sh
  pyperformance run --rigorous -o result.json
  ```

## Results

Table legend:

`Subj1` - official Docker image

`Subj2` - Debian package

`Subj3` - own package/image

### official Docker image versus Debian package

```text
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                     | Subj1    | Subj2    | Change       | Significance           |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| telco                         | 6.62 ms  | 4.80 ms  | 1.38x faster | Significant (t=217.40) |
| async_tree_eager_memoization  |  922 ms  |  682 ms  | 1.35x faster | Significant (t=51.47)  |
| async_tree_eager_io           | 1.67 sec | 1.24 sec | 1.35x faster | Significant (t=18.21)  |
| regex_effbot                  | 3.07 ms  | 2.29 ms  | 1.34x faster | Significant (t=167.58) |
| scimark_sparse_mat_mult       | 4.13 ms  | 3.13 ms  | 1.32x faster | Significant (t=79.28)  |
| pidigits                      |  190 ms  |  145 ms  | 1.31x faster | Significant (t=6.35)   |
| scimark_fft                   |  283 ms  |  217 ms  | 1.30x faster | Significant (t=28.62)  |
| spectral_norm                 | 92.0 ms  | 72.9 ms  | 1.26x faster | Significant (t=81.69)  |
| meteor_contest                | 97.2 ms  | 77.3 ms  | 1.26x faster | Significant (t=137.44) |
| json_dumps                    | 11.9 ms  | 9.48 ms  | 1.26x faster | Significant (t=102.55) |
| nbody                         | 85.7 ms  | 69.5 ms  | 1.23x faster | Significant (t=39.13)  |
| async_tree_eager_cpu_io_mixed |  866 ms  |  719 ms  | 1.20x faster | Significant (t=26.10)  |
| async_tree_io                 | 1.56 sec | 1.32 sec | 1.18x faster | Significant (t=17.29)  |
| regex_v8                      | 20.4 ms  | 17.5 ms  | 1.17x faster | Significant (t=98.46)  |
| regex_dna                     |  155 ms  |  133 ms  | 1.17x faster | Significant (t=97.95)  |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                   |  915 ms  | 1.24 sec | 1.36x slower | Significant (t=-32.22) |
| dask                          |  470 ms  |  575 ms  | 1.22x slower | Significant (t=-32.12) |
| asyncio_tcp_ssl               | 2.09 sec | 2.23 sec | 1.07x slower | Significant (t=-16.61) |
| coverage                      | 65.0 ms  | 69.1 ms  | 1.06x slower | Significant (t=-24.77) |
| richards                      | 38.6 ms  | 40.5 ms  | 1.05x slower | Significant (t=-13.53) |
| gc_traversal                  | 2.76 ms  | 2.85 ms  | 1.03x slower | Significant (t=-4.13)  |
| richards_super                | 49.5 ms  | 50.6 ms  | 1.02x slower | Significant (t=-4.60)  |
| docutils                      | 2.59 sec | 2.63 sec | 1.02x slower | Not significant        |
| go                            |  125 ms  |  125 ms  | 1.00x slower | Not significant        |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
```

### Debian package versus own package/image

```text
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                     | Subj2    | Subj3    | Change       | Significance           |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| gc_traversal                  | 2.85 ms  | 2.10 ms  | 1.36x faster | Significant (t=28.55)  |
| scimark_lu                    | 97.1 ms  | 72.2 ms  | 1.34x faster | Significant (t=10.98)  |
| dask                          |  575 ms  |  439 ms  | 1.31x faster | Significant (t=37.73)  |
| async_generators              |  266 ms  |  210 ms  | 1.27x faster | Significant (t=86.43)  |
| coverage                      | 69.1 ms  | 54.6 ms  | 1.27x faster | Significant (t=80.71)  |
| docutils                      | 2.63 sec | 2.08 sec | 1.27x faster | Significant (t=21.52)  |
| mdp                           | 2.75 sec | 2.19 sec | 1.26x faster | Significant (t=28.13)  |
| scimark_sparse_mat_mult       | 3.13 ms  | 2.51 ms  | 1.25x faster | Significant (t=74.48)  |
| xml_etree_iterparse           | 86.8 ms  | 71.4 ms  | 1.22x faster | Significant (t=21.76)  |
| asyncio_tcp                   | 1.24 sec | 1.02 sec | 1.21x faster | Significant (t=23.34)  |
| scimark_fft                   |  217 ms  |  180 ms  | 1.21x faster | Significant (t=16.89)  |
| coroutines                    | 21.7 ms  | 18.1 ms  | 1.20x faster | Significant (t=23.20)  |
| async_tree_io                 | 1.32 sec | 1.13 sec | 1.17x faster | Significant (t=16.91)  |
| xml_etree_parse               |  130 ms  |  112 ms  | 1.16x faster | Significant (t=68.81)  |
| 2to3                          |  241 ms  |  212 ms  | 1.14x faster | Significant (t=36.81)  |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| pidigits                      | 145 ms   |  148 ms  | 1.02x slower | Significant (t=-36.34) |
| mako                          | 8.15 ms  | 8.29 ms  | 1.02x slower | Not significant        |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
```

### official Docker image versus own package/image

```text
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                     | Subj1    | Subj3    | Change       | Significance           |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| scimark_sparse_mat_mult       | 4.13 ms  | 2.51 ms  | 1.65x faster | Significant (t=136.26) |
| scimark_fft                   |  283 ms  |  180 ms  | 1.57x faster | Significant (t=124.58) |
| telco                         | 6.62 ms  | 4.41 ms  | 1.50x faster | Significant (t=256.89) |
| async_tree_eager_memoization  |  922 ms  |  628 ms  | 1.47x faster | Significant (t=65.77)  |
| async_tree_eager_io           | 1.67 sec | 1.13 sec | 1.47x faster | Significant (t=23.95)  |
| async_generators              |  301 ms  |  210 ms  | 1.44x faster | Significant (t=131.02) |
| regex_effbot                  | 3.07 ms  | 2.21 ms  | 1.39x faster | Significant (t=155.51) |
| async_tree_io                 | 1.56 sec | 1.13 sec | 1.38x faster | Significant (t=49.15)  |
| scimark_lu                    | 97.2 ms  | 72.2 ms  | 1.35x faster | Significant (t=73.81)  |
| generators                    | 49.3 ms  | 37.4 ms  | 1.32x faster | Significant (t=71.68)  |
| gc_traversal                  | 2.76 ms  | 2.10 ms  | 1.32x faster | Significant (t=34.82)  |
| mdp                           | 2.89 sec | 2.19 sec | 1.32x faster | Significant (t=33.24)  |
| spectral_norm                 | 92.0 ms  | 69.5 ms  | 1.32x faster | Significant (t=154.23) |
| async_tree_eager_cpu_io_mixed |  866 ms  |  663 ms  | 1.31x faster | Significant (t=37.56)  |
| xml_etree_parse               |  143 ms  |  112 ms  | 1.28x faster | Significant (t=55.47)  |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                   |  915 ms  | 1.02 sec | 1.12x slower | Significant (t=-19.32) |
| ----------------------------- | -------- | -------- | ------------ | ---------------------- |
```

### raw results

```text
| ----------------------------- | ------------------- | ------------------- | ------------------- |
| benchmark name                |        Subj1        |        Subj2        |        Subj3        |
|                               | ------------------- | ------------------- | ------------------- |
|                               |   mean   | std dev  |   mean   | std dev  |   mean   | std dev  |
| ----------------------------- | ------------------- | ------------------- | ------------------- |
| 2to3                          |  253 ms  |    9 ms  |  241 ms  |    9 ms  |  212 ms  |    2 ms  |
| async_generators              |  301 ms  |    7 ms  |  266 ms  |    6 ms  |  210 ms  |    3 ms  |
| async_tree_none               |  579 ms  |   14 ms  |  509 ms  |   16 ms  |  481 ms  |    8 ms  |
| async_tree_cpu_io_mixed       |  790 ms  |   18 ms  |  693 ms  |   13 ms  |  674 ms  |   34 ms  |
| async_tree_eager              |  589 ms  |   19 ms  |  517 ms  |   28 ms  |  481 ms  |    9 ms  |
| async_tree_eager_cpu_io_mixed |  866 ms  |   56 ms  |  719 ms  |   25 ms  |  663 ms  |   18 ms  |
| async_tree_eager_io           | 1.67 sec | 0.24 sec | 1.24 sec | 0.09 sec | 1.13 sec | 0.02 sec |
| async_tree_eager_memoization  |  922 ms  |   45 ms  |  682 ms  |   24 ms  |  628 ms  |   19 ms  |
| async_tree_io                 | 1.56 sec | 0.09 sec | 1.32 sec | 0.12 sec | 1.13 sec | 0.02 sec |
| async_tree_memoization        |  720 ms  |   15 ms  |  716 ms  |   31 ms  |  628 ms  |   19 ms  |
| asyncio_tcp                   |  915 ms  |   53 ms  | 1.24 sec | 0.10 sec | 1.02 sec | 0.03 sec |
| asyncio_tcp_ssl               | 2.09 sec | 0.06 sec | 2.23 sec | 0.06 sec | 2.05 sec | 0.03 sec |
| chameleon                     | 6.08 ms  | 0.08 ms  | 5.78 ms  | 0.14 ms  | 5.34 ms  | 0.10 ms  |
| chaos                         | 63.3 ms  |  0.9 ms  | 57.3 ms  |  1.6 ms  | 55.0 ms  |  1.8 ms  |
| comprehensions                | 20.0 us  |  0.3 us  | 17.8 us  |  0.2 us  | 16.8 us  |  0.3 us  |
| bench_mp_pool                 | 31.0 ms  |  2.4 ms  | 29.1 ms  |  1.9 ms  | 28.9 ms  |  1.6 ms  |
| bench_thread_pool             | 1.21 ms  | 0.01 ms  | 1.18 ms  | 0.01 ms  | 1.14 ms  | 0.01 ms  |
| coroutines                    | 21.7 ms  |  0.6 ms  | 21.7 ms  |  0.5 ms  | 18.1 ms  |  1.6 ms  |
| coverage                      | 65.0 ms  |  1.0 ms  | 69.1 ms  |  1.5 ms  | 54.6 ms  |  1.3 ms  |
| crypto_pyaes                  | 66.5 ms  |  0.5 ms  | 58.1 ms  |  1.3 ms  | 56.4 ms  |  1.0 ms  |
| dask                          |  470 ms  |   16 ms  |  575 ms  |   32 ms  |  439 ms  |   23 ms  |
| deepcopy                      |  386 us  |    4 us  |  362 us  |    6 us  |  345 us  |    6 us  |
| deepcopy_reduce               | 2.80 us  | 0.05 us  | 2.60 us  | 0.02 us  | 2.44 us  | 0.03 us  |
| deepcopy_memo                 | 32.1 us  |  0.8 us  | 31.6 us  |  0.5 us  | 28.0 us  |  0.6 us  |
| deltablue                     | 3.30 ms  | 0.05 ms  | 3.25 ms  | 0.05 ms  | 2.95 ms  | 0.04 ms  |
| django_template               | 31.1 ms  |  0.4 ms  | 28.0 ms  |  0.4 ms  | 26.8 ms  |  0.7 ms  |
| docutils                      | 2.59 sec | 0.12 sec | 2.63 sec | 0.28 sec | 2.08 sec | 0.06 sec |
| dulwich_log                   | 64.4 ms  |  0.9 ms  | 60.7 ms  |  1.0 ms  | 57.9 ms  |  1.0 ms  |
| fannkuch                      |  305 ms  |    5 ms  |  297 ms  |    5 ms  |  279 ms  |    5 ms  |
| float                         | 68.2 ms  |  1.3 ms  | 60.8 ms  |  2.4 ms  | 57.8 ms  |  1.0 ms  |
| create_gc_cycles              |  895 us  |   12 us  |  856 us  |   13 us  |  802 us  |   18 us  |
| gc_traversal                  | 2.76 ms  | 0.08 ms  | 2.85 ms  | 0.21 ms  | 2.10 ms  | 0.19 ms  |
| generators                    | 49.3 ms  |  1.5 ms  | 42.3 ms  |  1.1 ms  | 37.4 ms  |  1.1 ms  |
| genshi_text                   | 20.3 ms  |  0.2 ms  | 19.0 ms  |  0.4 ms  | 18.4 ms  |  0.3 ms  |
| genshi_xml                    | 46.5 ms  |  0.6 ms  | 42.2 ms  |  0.6 ms  | 41.7 ms  |  0.6 ms  |
| go                            |  125 ms  |    3 ms  |  125 ms  |    3 ms  |  117 ms  |    4 ms  |
| hexiom                        | 5.58 ms  | 0.08 ms  | 5.28 ms  | 0.10 ms  | 5.07 ms  | 0.08 ms  |
| html5lib                      | 58.8 ms  |  2.7 ms  | 57.0 ms  |  3.9 ms  | 53.3 ms  |  3.2 ms  |
| json_dumps                    | 11.9 ms  |  0.2 ms  | 9.48 ms  | 0.12 ms  | 9.47 ms  | 0.10 ms  |
| json_loads                    | 25.3 us  |  0.3 us  | 17.1 us  |  0.2 us  | 17.8 us  |  0.2 us  |
| logging_format                | 8.43 us  | 0.10 us  | 7.85 us  | 0.20 us  | 7.58 us  | 0.13 us  |
| logging_silent                | 89.1 ns  |  2.5 ns  | 85.4 ns  |  1.2 ns  | 80.8 ns  |  1.8 ns  |
| logging_simple                | 7.88 us  | 0.06 us  | 7.30 us  | 0.19 us  | 7.03 us  | 0.13 us  |
| mako                          | 9.37 ms  | 0.31 ms  | 8.15 ms  | 0.31 ms  | 8.29 ms  | 0.60 ms  |
| mdp                           | 2.89 sec | 0.15 sec | 2.75 sec | 0.13 sec | 2.19 sec | 0.18 sec |
| meteor_contest                | 97.2 ms  |  1.5 ms  | 77.3 ms  |  0.6 ms  | 76.2 ms  |  0.9 ms  |
| nbody                         | 85.7 ms  |  4.0 ms  | 69.5 ms  |  2.2 ms  | 67.2 ms  |  1.7 ms  |
| nqueens                       | 77.8 ms  |  1.0 ms  | 67.1 ms  |  1.3 ms  | 66.7 ms  |  0.8 ms  |
| pathlib                       | 15.2 ms  |  0.2 ms  | 13.1 ms  |  0.3 ms  | 12.9 ms  |  0.6 ms  |
| pickle                        | 11.3 us  |  0.1 us  | 6.94 us  | 0.07 us  | 8.12 us  | 0.11 us  |
| pickle_dict                   | 26.6 us  |  0.3 us  | 16.5 us  |  0.2 us  | 19.4 us  |  0.2 us  |
| pickle_list                   | 3.97 us  | 0.05 us  | 2.04 us  | 0.12 us  | 2.70 us  | 0.15 us  |
| pickle_pure_python            |  377 us  |  154 us  |  237 us  |    4 us  |  236 us  |    3 us  |
| pidigits                      |  190 ms  |   78 ms  |  145 ms  |    1 ms  |  148 ms  |    1 ms  |
| pprint_safe_repr              |  656 ms  |  137 ms  |  574 ms  |    8 ms  |  558 ms  |    8 ms  |
| pprint_pformat                | 1.29 sec | 0.05 sec | 1.19 sec | 0.01 sec | 1.16 sec | 0.02 sec |
| pyflate                       |  374 ms  |    7 ms  |  346 ms  |    7 ms  |  336 ms  |   13 ms  |
| python_startup                | 7.68 ms  | 0.10 ms  | 7.44 ms  | 0.12 ms  | 7.31 ms  | 0.30 ms  |
| python_startup_no_site        | 5.69 ms  | 0.25 ms  | 5.11 ms  | 0.09 ms  | 4.99 ms  | 0.14 ms  |
| raytrace                      |  273 ms  |    4 ms  |  244 ms  |    3 ms  |  231 ms  |    4 ms  |
| regex_compile                 |  121 ms  |    1 ms  |  113 ms  |    2 ms  |  106 ms  |    3 ms  |
| regex_dna                     |  155 ms  |    2 ms  |  133 ms  |    1 ms  |  121 ms  |    2 ms  |
| regex_effbot                  | 3.07 ms  | 0.03 ms  | 2.29 ms  | 0.04 ms  | 2.21 ms  | 0.05 ms  |
| regex_v8                      | 20.4 ms  |  0.3 ms  | 17.5 ms  |  0.2 ms  | 16.4 ms  |  0.4 ms  |
| richards                      | 38.6 ms  |  1.0 ms  | 40.5 ms  |  1.2 ms  | 37.5 ms  |  1.0 ms  |
| richards_super                | 49.5 ms  |  2.3 ms  | 50.6 ms  |  1.2 ms  | 45.4 ms  |  0.9 ms  |
| scimark_fft                   |  283 ms  |    7 ms  |  217 ms  |   24 ms  |  180 ms  |    5 ms  |
| scimark_lu                    | 97.2 ms  |  3.4 ms  | 97.1 ms  | 24.8 ms  | 72.2 ms  |  1.6 ms  |
| scimark_monte_carlo           | 58.7 ms  |  1.0 ms  | 50.2 ms  |  2.8 ms  | 48.6 ms  |  1.4 ms  |
| scimark_sor                   | 96.2 ms  |  1.6 ms  | 89.5 ms  |  6.0 ms  | 84.1 ms  |  2.1 ms  |
| scimark_sparse_mat_mult       | 4.13 ms  | 0.12 ms  | 3.13 ms  | 0.07 ms  | 2.51 ms  | 0.06 ms  |
| spectral_norm                 | 92.0 ms  |  0.8 ms  | 72.9 ms  |  2.4 ms  | 69.5 ms  |  1.4 ms  |
| sqlalchemy_declarative        |  111 ms  |    5 ms  |  106 ms  |    5 ms  | 97.5 ms  |  2.4 ms  |
| sqlalchemy_imperative         | 16.9 ms  |  0.3 ms  | 16.3 ms  |  0.2 ms  | 14.9 ms  |  0.3 ms  |
| sqlglot_parse                 | 1.32 ms  | 0.03 ms  | 1.16 ms  | 0.03 ms  | 1.11 ms  | 0.06 ms  |
| sqlglot_transpile             | 1.57 ms  | 0.03 ms  | 1.41 ms  | 0.03 ms  | 1.31 ms  | 0.03 ms  |
| sqlglot_optimize              | 49.2 ms  |  0.5 ms  | 42.9 ms  |  0.4 ms  | 40.2 ms  |  0.7 ms  |
| sqlglot_normalize             |  261 ms  |    2 ms  |  224 ms  |    2 ms  |  213 ms  |    3 ms  |
| sqlite_synth                  | 2.23 us  | 0.03 us  | 2.06 us  | 0.02 us  | 1.85 us  | 0.02 us  |
| sympy_expand                  |  426 ms  |    5 ms  |  393 ms  |    4 ms  |  370 ms  |    6 ms  |
| sympy_integrate               | 18.4 ms  |  0.3 ms  | 17.4 ms  |  0.5 ms  | 16.3 ms  |  0.3 ms  |
| sympy_sum                     |  145 ms  |    2 ms  |  136 ms  |    2 ms  |  128 ms  |    3 ms  |
| sympy_str                     |  261 ms  |    2 ms  |  241 ms  |    2 ms  |  226 ms  |    4 ms  |
| telco                         | 6.62 ms  | 0.06 ms  | 4.80 ms  | 0.07 ms  | 4.41 ms  | 0.07 ms  |
| tomli_loads                   | 1.91 sec | 0.02 sec | 1.78 sec | 0.03 sec | 1.60 sec | 0.03 sec |
| tornado_http                  |  110 ms  |    3 ms  |  107 ms  |    5 ms  | 98.1 ms  |  3.7 ms  |
| typing_runtime_protocols      |  520 us  |    7 us  |  377 us  |    6 us  |  360 us  |    6 us  |
| unpack_sequence               | 37.2 ns  |  1.9 ns  | 32.9 ns  |  1.1 ns  | 31.1 ns  |  2.8 ns  |
| unpickle                      | 12.7 us  |  0.1 us  | 9.89 us  | 0.13 us  | 10.6 us  |  0.2 us  |
| unpickle_list                 | 4.50 us  | 0.09 us  | 3.33 us  | 0.07 us  | 3.63 us  | 0.09 us  |
| unpickle_pure_python          |  214 us  |    3 us  |  184 us  |    2 us  |  181 us  |    2 us  |
| xml_etree_parse               |  143 ms  |    6 ms  |  130 ms  |    2 ms  |  112 ms  |    1 ms  |
| xml_etree_iterparse           | 90.4 ms  |  3.3 ms  | 86.8 ms  |  7.7 ms  | 71.4 ms  |  0.5 ms  |
| xml_etree_generate            | 67.5 ms  |  0.9 ms  | 59.9 ms  |  1.6 ms  | 55.0 ms  |  0.5 ms  |
| xml_etree_process             | 48.4 ms  |  1.0 ms  | 44.4 ms  |  1.0 ms  | 41.5 ms  |  0.7 ms  |
| ----------------------------- | ------------------- | ------------------- | ------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | mawk '$5 ~ "[nu]s" {next} {print}' | sort -rk10 | head -n "${4:-15}" ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster "$3" ; echo ; _pyperf_compare "$1" "$2" slower "$3" ; }

  n=$(awk '{print $1}' < raw.txt | wc -L) ; while read -r name data ; do printf "| %-${n}s |" "${name}" ; printf ' %4s %-3s |' ${data} ; echo ; done < raw.txt
  ```
