# Python 3.11.4 benchmarks

Date: 14.08.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), commit ef1d636b

## Subjects

- official Docker image: docker.io/library/python:3.11.4-slim-bookworm
- Debian package `python3.11=3.11.4-1`
- own [package](../../package/python)/image: docker.io/rockdrilla/python:3.11.4-bookworm

## Prerequisites

- install Debian package `build-essential` in order to build Python packages:

  ```sh
  apt update && apt upgrade -y && apt install -y build-essential && apt clean
  ```

- pure Debian's Python: install Debian packages `python3-dev` and `python3-pip` in order to install and build Python packages:

  ```sh
  apt update && apt install -y python3-dev python3-pip python3-venv && apt clean
  ```

- install `pyperformance`:

  ```sh
  pip install --no-binary :all: https://github.com/python/pyperformance/archive/ef1d636b.tar.gz
  ```

  NB: Debian requires `--break-system-packages` flag to be passed for `pip install`, e.g.:

  ```sh
  pip install --break-system-packages --no-binary :all: https://github.com/python/pyperformance/archive/ef1d636b.tar.gz
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
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| Benchmark                  | Docker   | [own]    | Change       | Significance            |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| scimark_sparse_mat_mult    | 4.19 ms  | 2.52 ms  | 1.66x faster | Significant (t=152.32)  |
| scimark_fft                |  276 ms  |  178 ms  | 1.55x faster | Significant (t=142.37)  |
| json_loads                 | 26.4 us  | 17.5 us  | 1.51x faster | Significant (t=230.33)  |
| telco                      | 7.46 ms  | 4.93 ms  | 1.51x faster | Significant (t=140.09)  |
| pickle                     | 11.4 us  | 7.80 us  | 1.46x faster | Significant (t=284.14)  |
| sqlglot_optimize           | 57.3 ms  | 39.8 ms  | 1.44x faster | Significant (t=63.52)   |
| pickle_list                | 4.01 us  | 2.82 us  | 1.43x faster | Significant (t=144.87)  |
| typing_runtime_protocols   |  530 us  |  371 us  | 1.43x faster | Significant (t=142.09)  |
| spectral_norm              | 96.4 ms  | 68.3 ms  | 1.41x faster | Significant (t=179.81)  |
| pickle_dict                | 27.8 us  | 20.2 us  | 1.38x faster | Significant (t=148.87)  |
| unpickle_list              | 4.70 us  | 3.58 us  | 1.31x faster | Significant (t=77.64)   |
| async_generators           |  300 ms  |  229 ms  | 1.31x faster | Significant (t=61.35)   |
| generators                 | 50.3 ms  | 38.7 ms  | 1.30x faster | Significant (t=89.40)   |
| sympy_expand               |  486 ms  |  374 ms  | 1.30x faster | Significant (t=31.42)   |
| coverage                   | 67.4 ms  | 51.7 ms  | 1.30x faster | Significant (t=132.31)  |
| sympy_str                  |  295 ms  |  230 ms  | 1.28x faster | Significant (t=86.56)   |
| tomli_loads                | 2.06 sec | 1.62 sec | 1.28x faster | Significant (t=31.23)   |
| float                      | 69.0 ms  | 54.6 ms  | 1.27x faster | Significant (t=103.93)  |
| xml_etree_parse            |  147 ms  |  116 ms  | 1.26x faster | Significant (t=53.32)   |
| raytrace                   |  279 ms  |  223 ms  | 1.25x faster | Significant (t=80.25)   |
| scimark_lu                 | 97.8 ms  | 78.2 ms  | 1.25x faster | Significant (t=52.19)   |
| meteor_contest             | 94.2 ms  | 75.1 ms  | 1.25x faster | Significant (t=148.55)  |
| unpickle                   | 12.6 us  | 10.1 us  | 1.25x faster | Significant (t=120.44)  |
| nqueens                    | 79.1 ms  | 63.8 ms  | 1.24x faster | Significant (t=80.16)   |
| sqlglot_parse              | 1.37 ms  | 1.10 ms  | 1.24x faster | Significant (t=47.70)   |
| scimark_monte_carlo        | 58.0 ms  | 46.6 ms  | 1.24x faster | Significant (t=124.34)  |
| sqlglot_transpile          | 1.63 ms  | 1.33 ms  | 1.23x faster | Significant (t=89.45)   |
| xml_etree_iterparse        | 91.8 ms  | 74.5 ms  | 1.23x faster | Significant (t=44.89)   |
| mdp                        | 2.49 sec | 2.02 sec | 1.23x faster | Significant (t=32.31)   |
| json_dumps                 | 10.7 ms  | 8.74 ms  | 1.22x faster | Significant (t=121.75)  |
| pickle_pure_python         |  287 us  |  234 us  | 1.22x faster | Significant (t=104.41)  |
| deepcopy_memo              | 33.2 us  | 27.4 us  | 1.21x faster | Significant (t=91.09)   |
| xml_etree_generate         | 68.6 ms  | 56.9 ms  | 1.21x faster | Significant (t=55.16)   |
| crypto_pyaes               | 68.3 ms  | 56.5 ms  | 1.21x faster | Significant (t=47.35)   |
| chaos                      | 63.4 ms  | 52.7 ms  | 1.20x faster | Significant (t=89.82)   |
| hexiom                     | 5.83 ms  | 4.87 ms  | 1.20x faster | Significant (t=79.70)   |
| nbody                      | 85.0 ms  | 70.6 ms  | 1.20x faster | Significant (t=55.95)   |
| unpack_sequence            | 36.6 ns  | 30.6 ns  | 1.20x faster | Significant (t=47.77)   |
| scimark_sor                |  100 ms  | 83.6 ms  | 1.20x faster | Significant (t=38.49)   |
| async_tree_memoization_tg  |  591 ms  |  492 ms  | 1.20x faster | Significant (t=26.92)   |
| fannkuch                   |  318 ms  |  267 ms  | 1.19x faster | Significant (t=81.19)   |
| async_tree_cpu_io_mixed_tg |  700 ms  |  589 ms  | 1.19x faster | Significant (t=37.54)   |
| unpickle_pure_python       |  213 us  |  178 us  | 1.19x faster | Significant (t=127.46)  |
| deepcopy_reduce            | 2.86 us  | 2.40 us  | 1.19x faster | Significant (t=105.37)  |
| sqlite_synth               | 2.35 us  | 1.99 us  | 1.18x faster | Significant (t=88.16)   |
| html5lib                   | 61.9 ms  | 52.3 ms  | 1.18x faster | Significant (t=28.19)   |
| pprint_safe_repr           |  644 ms  |  546 ms  | 1.18x faster | Significant (t=114.90)  |
| genshi_xml                 | 45.9 ms  | 39.1 ms  | 1.17x faster | Significant (t=90.46)   |
| sympy_sum                  |  154 ms  |  131 ms  | 1.17x faster | Significant (t=80.97)   |
| sympy_integrate            | 19.3 ms  | 16.5 ms  | 1.17x faster | Significant (t=77.88)   |
| pprint_pformat             | 1.33 sec | 1.14 sec | 1.17x faster | Significant (t=55.01)   |
| docutils                   | 2.42 sec | 2.06 sec | 1.17x faster | Significant (t=38.70)   |
| async_tree_cpu_io_mixed    |  763 ms  |  654 ms  | 1.17x faster | Significant (t=29.02)   |
| genshi_text                | 20.1 ms  | 17.3 ms  | 1.16x faster | Significant (t=61.30)   |
| 2to3                       |  244 ms  |  210 ms  | 1.16x faster | Significant (t=32.36)   |
| async_tree_io_tg           | 1.17 sec | 1.02 sec | 1.16x faster | Significant (t=27.83)   |
| gc_traversal               | 2.87 ms  | 2.47 ms  | 1.16x faster | Significant (t=17.08)   |
| django_template            | 30.9 ms  | 26.9 ms  | 1.15x faster | Significant (t=61.89)   |
| regex_effbot               | 2.57 ms  | 2.23 ms  | 1.15x faster | Significant (t=24.68)   |
| regex_compile              |  124 ms  |  109 ms  | 1.14x faster | Significant (t=79.04)   |
| comprehensions             | 20.1 us  | 17.6 us  | 1.14x faster | Significant (t=71.20)   |
| deltablue                  | 3.35 ms  | 2.93 ms  | 1.14x faster | Significant (t=47.69)   |
| sqlalchemy_imperative      | 17.9 ms  | 15.7 ms  | 1.14x faster | Significant (t=36.92)   |
| regex_v8                   | 18.3 ms  | 16.1 ms  | 1.14x faster | Significant (t=27.68)   |
| async_tree_none_tg         |  431 ms  |  379 ms  | 1.14x faster | Significant (t=18.78)   |
| chameleon                  | 6.00 ms  | 5.29 ms  | 1.13x faster | Significant (t=83.53)   |
| go                         |  125 ms  |  111 ms  | 1.13x faster | Significant (t=72.46)   |
| pathlib                    | 14.5 ms  | 12.8 ms  | 1.13x faster | Significant (t=56.12)   |
| sqlalchemy_declarative     |  112 ms  | 99.5 ms  | 1.13x faster | Significant (t=27.08)   |
| xml_etree_process          | 48.5 ms  | 42.8 ms  | 1.13x faster | Significant (t=22.99)   |
| logging_format             | 8.61 us  | 7.71 us  | 1.12x faster | Significant (t=65.71)   |
| logging_simple             | 7.97 us  | 7.14 us  | 1.12x faster | Significant (t=59.67)   |
| pyflate                    |  369 ms  |  328 ms  | 1.12x faster | Significant (t=58.97)   |
| deepcopy                   |  389 us  |  349 us  | 1.12x faster | Significant (t=57.26)   |
| dulwich_log                | 65.9 ms  | 59.3 ms  | 1.11x faster | Significant (t=65.17)   |
| richards_super             | 50.8 ms  | 45.6 ms  | 1.11x faster | Significant (t=38.91)   |
| async_tree_io              | 1.27 sec | 1.14 sec | 1.11x faster | Significant (t=19.61)   |
| logging_silent             | 86.0 ns  | 78.2 ns  | 1.10x faster | Significant (t=38.47)   |
| richards                   | 40.7 ms  | 36.9 ms  | 1.10x faster | Significant (t=29.76)   |
| coroutines                 | 22.6 ms  | 20.5 ms  | 1.10x faster | Significant (t=29.23)   |
| pidigits                   |  156 ms  |  141 ms  | 1.10x faster | Significant (t=247.97)  |
| async_tree_memoization     |  657 ms  |  597 ms  | 1.10x faster | Significant (t=21.14)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| sqlglot_normalize          |  107 ms  |  213 ms  | 2.00x slower | Significant (t=-134.30) |
| asyncio_tcp                |  800 ms  |  995 ms  | 1.24x slower | Significant (t=-45.92)  |
| asyncio_tcp_ssl            | 2.05 sec | 2.13 sec | 1.04x slower | Significant (t=-9.47)   |
| bench_mp_pool              | 28.4 ms  | 29.3 ms  | 1.03x slower | Significant (t=-3.88)   |
| asyncio_websockets         |  521 ms  |  526 ms  | 1.01x slower | Not significant         |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

### Debian package versus own package/image

```text
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| Benchmark                  | Debian   | [own]    | Change       | Significance            |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| unpack_sequence            | 41.9 ns  | 30.6 ns  | 1.37x faster | Significant (t=10.07)   |
| coverage                   | 68.3 ms  | 51.7 ms  | 1.32x faster | Significant (t=117.43)  |
| scimark_sparse_mat_mult    | 3.15 ms  | 2.52 ms  | 1.25x faster | Significant (t=39.22)   |
| mdp                        | 2.53 sec | 2.02 sec | 1.25x faster | Significant (t=27.54)   |
| tornado_http               |  125 ms  |  101 ms  | 1.24x faster | Significant (t=7.11)    |
| scimark_fft                |  217 ms  |  178 ms  | 1.22x faster | Significant (t=79.50)   |
| async_generators           |  275 ms  |  229 ms  | 1.20x faster | Significant (t=27.81)   |
| regex_effbot               | 2.65 ms  | 2.23 ms  | 1.19x faster | Significant (t=28.79)   |
| tomli_loads                | 1.92 sec | 1.62 sec | 1.19x faster | Significant (t=11.91)   |
| richards                   | 43.4 ms  | 36.9 ms  | 1.17x faster | Significant (t=20.10)   |
| asyncio_tcp                | 1.16 sec |  995 ms  | 1.17x faster | Significant (t=15.71)   |
| richards_super             | 53.1 ms  | 45.6 ms  | 1.16x faster | Significant (t=35.03)   |
| 2to3                       |  240 ms  |  210 ms  | 1.14x faster | Significant (t=33.17)   |
| deepcopy_memo              | 30.9 us  | 27.4 us  | 1.13x faster | Significant (t=43.42)   |
| coroutines                 | 22.9 ms  | 20.5 ms  | 1.12x faster | Significant (t=43.52)   |
| xml_etree_parse            |  129 ms  |  116 ms  | 1.11x faster | Significant (t=24.61)   |
| sqlglot_optimize           | 43.7 ms  | 39.8 ms  | 1.10x faster | Significant (t=79.29)   |
| genshi_xml                 | 42.9 ms  | 39.1 ms  | 1.10x faster | Significant (t=46.52)   |
| go                         |  123 ms  |  111 ms  | 1.10x faster | Significant (t=45.55)   |
| regex_v8                   | 17.7 ms  | 16.1 ms  | 1.10x faster | Significant (t=20.08)   |
| scimark_sor                | 91.6 ms  | 83.6 ms  | 1.10x faster | Significant (t=19.59)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| pickle_list                | 2.00 us  | 2.82 us  | 1.41x slower | Significant (t=-150.47) |
| pickle_dict                | 16.5 us  | 20.2 us  | 1.23x slower | Significant (t=-119.58) |
| pickle                     | 6.87 us  | 7.80 us  | 1.13x slower | Significant (t=-69.94)  |
| unpickle_list              | 3.30 us  | 3.58 us  | 1.08x slower | Significant (t=-21.77)  |
| gc_traversal               | 2.36 ms  | 2.47 ms  | 1.05x slower | Significant (t=-7.15)   |
| mako                       | 7.77 ms  | 7.97 ms  | 1.03x slower | Significant (t=-8.88)   |
| json_loads                 | 17.0 us  | 17.5 us  | 1.03x slower | Significant (t=-18.68)  |
| python_startup_no_site     | 4.80 ms  | 4.90 ms  | 1.02x slower | Significant (t=-11.67)  |
| asyncio_websockets         |  518 ms  |  526 ms  | 1.02x slower | Not significant         |
| pidigits                   |  140 ms  |  141 ms  | 1.01x slower | Not significant         |
| unpickle                   | 10.1 us  | 10.1 us  | 1.00x slower | Not significant         |
| telco                      | 4.91 ms  | 4.93 ms  | 1.00x slower | Not significant         |
| python_startup             | 6.68 ms  | 6.70 ms  | 1.00x slower | Not significant         |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

### official Docker image versus Debian package

```text
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| Benchmark                  | Docker   | Debian   | Change       | Significance            |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| pickle_list                | 4.01 us  | 2.00 us  | 2.01x faster | Significant (t=281.01)  |
| pickle_dict                | 27.8 us  | 16.5 us  | 1.69x faster | Significant (t=195.29)  |
| pickle                     | 11.4 us  | 6.87 us  | 1.66x faster | Significant (t=295.22)  |
| json_loads                 | 26.4 us  | 17.0 us  | 1.56x faster | Significant (t=254.37)  |
| telco                      | 7.46 ms  | 4.91 ms  | 1.52x faster | Significant (t=148.74)  |
| unpickle_list              | 4.70 us  | 3.30 us  | 1.42x faster | Significant (t=138.12)  |
| scimark_sparse_mat_mult    | 4.19 ms  | 3.15 ms  | 1.33x faster | Significant (t=56.69)   |
| typing_runtime_protocols   |  530 us  |  403 us  | 1.32x faster | Significant (t=16.48)   |
| spectral_norm              | 96.4 ms  | 73.2 ms  | 1.32x faster | Significant (t=106.45)  |
| sqlglot_optimize           | 57.3 ms  | 43.7 ms  | 1.31x faster | Significant (t=49.23)   |
| scimark_fft                |  276 ms  |  217 ms  | 1.27x faster | Significant (t=99.16)   |
| unpickle                   | 12.6 us  | 10.1 us  | 1.25x faster | Significant (t=30.60)   |
| generators                 | 50.3 ms  | 40.8 ms  | 1.24x faster | Significant (t=63.10)   |
| float                      | 69.0 ms  | 56.0 ms  | 1.23x faster | Significant (t=97.81)   |
| gc_traversal               | 2.87 ms  | 2.36 ms  | 1.22x faster | Significant (t=28.17)   |
| sympy_expand               |  486 ms  |  398 ms  | 1.22x faster | Significant (t=24.85)   |
| meteor_contest             | 94.2 ms  | 76.9 ms  | 1.22x faster | Significant (t=116.47)  |
| sympy_str                  |  295 ms  |  243 ms  | 1.21x faster | Significant (t=69.23)   |
| crypto_pyaes               | 68.3 ms  | 56.6 ms  | 1.21x faster | Significant (t=124.91)  |
| chaos                      | 63.4 ms  | 52.9 ms  | 1.20x faster | Significant (t=84.47)   |
| raytrace                   |  279 ms  |  235 ms  | 1.19x faster | Significant (t=47.63)   |
| nbody                      | 85.0 ms  | 71.6 ms  | 1.19x faster | Significant (t=35.80)   |
| fannkuch                   |  318 ms  |  270 ms  | 1.18x faster | Significant (t=48.64)   |
| sqlglot_parse              | 1.37 ms  | 1.16 ms  | 1.18x faster | Significant (t=35.26)   |
| pickle_pure_python         |  287 us  |  245 us  | 1.17x faster | Significant (t=71.29)   |
| scimark_lu                 | 97.8 ms  | 83.3 ms  | 1.17x faster | Significant (t=38.75)   |
| sqlglot_transpile          | 1.63 ms  | 1.41 ms  | 1.16x faster | Significant (t=66.34)   |
| json_dumps                 | 10.7 ms  | 9.26 ms  | 1.16x faster | Significant (t=107.36)  |
| scimark_monte_carlo        | 58.0 ms  | 49.9 ms  | 1.16x faster | Significant (t=102.13)  |
| nqueens                    | 79.1 ms  | 68.5 ms  | 1.15x faster | Significant (t=50.04)   |
| sqlite_synth               | 2.35 us  | 2.07 us  | 1.14x faster | Significant (t=76.99)   |
| pprint_safe_repr           |  644 ms  |  565 ms  | 1.14x faster | Significant (t=71.53)   |
| html5lib                   | 61.9 ms  | 54.4 ms  | 1.14x faster | Significant (t=22.22)   |
| unpickle_pure_python       |  213 us  |  188 us  | 1.13x faster | Significant (t=94.91)   |
| comprehensions             | 20.1 us  | 17.7 us  | 1.13x faster | Significant (t=59.82)   |
| xml_etree_generate         | 68.6 ms  | 60.9 ms  | 1.13x faster | Significant (t=53.36)   |
| xml_etree_parse            |  147 ms  |  129 ms  | 1.13x faster | Significant (t=51.88)   |
| django_template            | 30.9 ms  | 27.5 ms  | 1.13x faster | Significant (t=45.46)   |
| xml_etree_iterparse        | 91.8 ms  | 81.3 ms  | 1.13x faster | Significant (t=28.96)   |
| docutils                   | 2.42 sec | 2.14 sec | 1.13x faster | Significant (t=26.07)   |
| async_tree_memoization_tg  |  591 ms  |  522 ms  | 1.13x faster | Significant (t=16.38)   |
| pathlib                    | 14.5 ms  | 13.0 ms  | 1.12x faster | Significant (t=52.78)   |
| pprint_pformat             | 1.33 sec | 1.19 sec | 1.12x faster | Significant (t=33.55)   |
| sympy_integrate            | 19.3 ms  | 17.4 ms  | 1.11x faster | Significant (t=85.40)   |
| sympy_sum                  |  154 ms  |  138 ms  | 1.11x faster | Significant (t=60.36)   |
| chameleon                  | 6.00 ms  | 5.42 ms  | 1.11x faster | Significant (t=58.12)   |
| logging_format             | 8.61 us  | 7.77 us  | 1.11x faster | Significant (t=48.66)   |
| pidigits                   |  156 ms  |  140 ms  | 1.11x faster | Significant (t=298.06)  |
| async_tree_io_tg           | 1.17 sec | 1.06 sec | 1.11x faster | Significant (t=20.91)   |
| logging_simple             | 7.97 us  | 7.25 us  | 1.10x faster | Significant (t=62.92)   |
| hexiom                     | 5.83 ms  | 5.31 ms  | 1.10x faster | Significant (t=56.09)   |
| dulwich_log                | 65.9 ms  | 59.7 ms  | 1.10x faster | Significant (t=53.18)   |
| deepcopy_reduce            | 2.86 us  | 2.61 us  | 1.10x faster | Significant (t=52.16)   |
| pyflate                    |  369 ms  |  334 ms  | 1.10x faster | Significant (t=33.91)   |
| async_tree_cpu_io_mixed_tg |  700 ms  |  634 ms  | 1.10x faster | Significant (t=22.21)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| sqlglot_normalize          |  107 ms  |  230 ms  | 2.16x slower | Significant (t=-158.20) |
| asyncio_tcp                |  800 ms  | 1.16 sec | 1.45x slower | Significant (t=-34.53)  |
| tornado_http               |  109 ms  |  125 ms  | 1.15x slower | Significant (t=-4.62)   |
| unpack_sequence            | 36.6 ns  | 41.9 ns  | 1.14x slower | Significant (t=-4.67)   |
| asyncio_tcp_ssl            | 2.05 sec | 2.20 sec | 1.08x slower | Significant (t=-12.82)  |
| richards                   | 40.7 ms  | 43.4 ms  | 1.07x slower | Significant (t=-8.33)   |
| richards_super             | 50.8 ms  | 53.1 ms  | 1.05x slower | Significant (t=-10.07)  |
| bench_mp_pool              | 28.4 ms  | 29.4 ms  | 1.04x slower | Significant (t=-4.01)   |
| regex_effbot               | 2.57 ms  | 2.65 ms  | 1.03x slower | Significant (t=-13.08)  |
| mdp                        | 2.49 sec | 2.53 sec | 1.02x slower | Not significant         |
| coverage                   | 67.4 ms  | 68.3 ms  | 1.01x slower | Not significant         |
| coroutines                 | 22.6 ms  | 22.9 ms  | 1.01x slower | Not significant         |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
