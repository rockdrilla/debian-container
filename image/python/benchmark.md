# Python 3.11.4 benchmarks

Date: 12.08.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), release 1.0.9

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
  apt update && apt install -y python3-dev python3-pip && apt clean
  ```

- install `pyperformance`:

  ```sh
  pip install pyperformance==1.0.9
  ```

  NB: Debian requires `--break-system-packages` flag to be passed for `pip install`, e.g.:

  ```sh
  pip install --break-system-packages pyperformance==1.0.9
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
| xml_etree_iterparse        |  132 ms  | 73.0 ms  | 1.81x faster | Significant (t=29.01)   |
| scimark_fft                |  328 ms  |  189 ms  | 1.73x faster | Significant (t=52.98)   |
| scimark_sparse_mat_mult    | 4.69 ms  | 2.76 ms  | 1.70x faster | Significant (t=126.68)  |
| unpickle_list              | 5.22 us  | 3.24 us  | 1.61x faster | Significant (t=58.32)   |
| xml_etree_parse            |  190 ms  |  118 ms  | 1.61x faster | Significant (t=20.04)   |
| sqlalchemy_imperative      | 24.1 ms  | 15.2 ms  | 1.59x faster | Significant (t=29.18)   |
| typing_runtime_protocols   |  577 ms  |  368 ms  | 1.57x faster | Significant (t=79.25)   |
| pickle_list                | 4.23 us  | 2.71 us  | 1.56x faster | Significant (t=96.29)   |
| pickle_dict                | 30.5 us  | 20.0 us  | 1.53x faster | Significant (t=57.70)   |
| pickle                     | 11.9 us  | 7.78 us  | 1.53x faster | Significant (t=216.36)  |
| json_loads                 | 26.4 us  | 17.3 us  | 1.53x faster | Significant (t=126.86)  |
| regex_compile              |  159 ms  |  105 ms  | 1.51x faster | Significant (t=34.92)   |
| telco                      | 7.12 ms  | 4.81 ms  | 1.48x faster | Significant (t=121.52)  |
| spectral_norm              |  106 ms  | 74.1 ms  | 1.43x faster | Significant (t=100.72)  |
| unpack_sequence            | 43.7 ns  | 30.8 ns  | 1.42x faster | Significant (t=32.71)   |
| docutils                   | 2.86 sec | 2.03 sec | 1.41x faster | Significant (t=49.46)   |
| mdp                        | 2.91 sec | 2.06 sec | 1.41x faster | Significant (t=26.91)   |
| async_tree_memoization_tg  |  699 ms  |  504 ms  | 1.39x faster | Significant (t=15.74)   |
| async_tree_memoization     |  816 ms  |  592 ms  | 1.38x faster | Significant (t=35.44)   |
| raytrace                   |  317 ms  |  229 ms  | 1.38x faster | Significant (t=24.10)   |
| tomli_loads                | 2.22 sec | 1.62 sec | 1.37x faster | Significant (t=29.25)   |
| coverage                   | 69.1 ms  | 50.5 ms  | 1.37x faster | Significant (t=105.24)  |
| unpickle                   | 13.4 us  | 9.86 us  | 1.36x faster | Significant (t=43.18)   |
| async_tree_cpu_io_mixed_tg |  782 ms  |  581 ms  | 1.34x faster | Significant (t=24.26)   |
| generators                 | 51.5 ms  | 38.8 ms  | 1.33x faster | Significant (t=62.01)   |
| gc_traversal               | 3.11 ms  | 2.34 ms  | 1.33x faster | Significant (t=39.36)   |
| xml_etree_generate         | 78.7 ms  | 59.4 ms  | 1.32x faster | Significant (t=31.01)   |
| meteor_contest             | 98.0 ms  | 75.0 ms  | 1.31x faster | Significant (t=99.19)   |
| async_tree_none_tg         |  494 ms  |  379 ms  | 1.30x faster | Significant (t=65.15)   |
| scimark_monte_carlo        | 61.5 ms  | 48.2 ms  | 1.28x faster | Significant (t=67.83)   |
| async_generators           |  294 ms  |  230 ms  | 1.28x faster | Significant (t=55.40)   |
| sqlglot_parse              | 1.38 ms  | 1.08 ms  | 1.28x faster | Significant (t=55.13)   |
| regex_effbot               | 2.87 ms  | 2.24 ms  | 1.28x faster | Significant (t=42.61)   |
| regex_dna                  |  160 ms  |  125 ms  | 1.28x faster | Significant (t=31.72)   |
| pickle_pure_python         |  295 ms  |  231 ms  | 1.28x faster | Significant (t=102.74)  |
| scimark_sor                |  109 ms  | 85.7 ms  | 1.27x faster | Significant (t=77.33)   |
| sqlalchemy_declarative     |  122 ms  | 96.1 ms  | 1.27x faster | Significant (t=55.97)   |
| scimark_lu                 |  103 ms  | 80.9 ms  | 1.27x faster | Significant (t=54.62)   |
| sqlglot_transpile          | 1.66 ms  | 1.31 ms  | 1.27x faster | Significant (t=41.55)   |
| async_tree_io_tg           | 1.30 sec | 1.02 sec | 1.27x faster | Significant (t=17.80)   |
| sqlite_synth               | 2.40 us  | 1.90 us  | 1.26x faster | Significant (t=48.53)   |
| xml_etree_process          | 55.0 ms  | 43.6 ms  | 1.26x faster | Significant (t=31.24)   |
| json_dumps                 | 10.8 ms  | 8.69 ms  | 1.25x faster | Significant (t=83.51)   |
| crypto_pyaes               | 70.2 ms  | 55.9 ms  | 1.25x faster | Significant (t=66.61)   |
| unpickle_pure_python       |  229 ms  |  183 ms  | 1.25x faster | Significant (t=49.53)   |
| regex_v8                   | 21.0 ms  | 16.8 ms  | 1.25x faster | Significant (t=26.77)   |
| dask                       |  519 ms  |  421 ms  | 1.24x faster | Significant (t=48.69)   |
| sympy_integrate            | 19.9 ms  | 16.1 ms  | 1.24x faster | Significant (t=32.23)   |
| richards_super             | 56.1 ms  | 45.5 ms  | 1.24x faster | Significant (t=26.49)   |
| async_tree_cpu_io_mixed    |  809 ms  |  654 ms  | 1.24x faster | Significant (t=19.26)   |
| pathlib                    | 15.0 ms  | 12.3 ms  | 1.22x faster | Significant (t=85.60)   |
| chaos                      | 65.6 ms  | 53.9 ms  | 1.22x faster | Significant (t=85.37)   |
| float                      | 70.9 ms  | 58.2 ms  | 1.22x faster | Significant (t=69.54)   |
| sympy_expand               |  453 ms  |  371 ms  | 1.22x faster | Significant (t=45.95)   |
| deepcopy_memo              | 32.9 us  | 26.9 us  | 1.22x faster | Significant (t=34.01)   |
| sqlglot_optimize           | 48.9 ms  | 40.3 ms  | 1.21x faster | Significant (t=98.47)   |
| sympy_sum                  |  152 ms  |  127 ms  | 1.20x faster | Significant (t=91.02)   |
| nqueens                    | 80.3 ms  | 66.9 ms  | 1.20x faster | Significant (t=81.00)   |
| sympy_str                  |  271 ms  |  229 ms  | 1.19x faster | Significant (t=85.93)   |
| dulwich_log                | 68.4 ms  | 57.5 ms  | 1.19x faster | Significant (t=53.14)   |
| deepcopy_reduce            | 2.85 us  | 2.39 us  | 1.19x faster | Significant (t=45.17)   |
| richards                   | 44.1 ms  | 37.0 ms  | 1.19x faster | Significant (t=24.33)   |
| django_template            | 31.8 ms  | 27.0 ms  | 1.18x faster | Significant (t=61.03)   |
| chameleon                  | 6.11 ms  | 5.19 ms  | 1.18x faster | Significant (t=56.53)   |
| mako                       | 8.73 ms  | 7.41 ms  | 1.18x faster | Significant (t=35.97)   |
| async_tree_io              | 1.32 sec | 1.12 sec | 1.18x faster | Significant (t=23.92)   |
| logging_format             | 8.78 us  | 7.52 us  | 1.17x faster | Significant (t=67.43)   |
| hexiom                     | 5.92 ms  | 5.04 ms  | 1.17x faster | Significant (t=47.07)   |
| python_startup_no_site     | 5.57 ms  | 4.76 ms  | 1.17x faster | Significant (t=37.81)   |
| tornado_http               |  113 ms  | 96.4 ms  | 1.17x faster | Significant (t=32.77)   |
| pprint_pformat             | 1.39 sec | 1.20 sec | 1.16x faster | Significant (t=64.98)   |
| pidigits                   |  163 ms  |  141 ms  | 1.16x faster | Significant (t=59.65)   |
| comprehensions             | 20.7 us  | 17.9 us  | 1.16x faster | Significant (t=45.26)   |
| bench_mp_pool              | 34.2 ms  | 29.6 ms  | 1.16x faster | Significant (t=15.46)   |
| pprint_safe_repr           |  669 ms  |  582 ms  | 1.15x faster | Significant (t=61.09)   |
| logging_simple             | 8.06 us  | 7.05 us  | 1.14x faster | Significant (t=69.22)   |
| deltablue                  | 3.41 ms  | 3.00 ms  | 1.14x faster | Significant (t=39.41)   |
| create_gc_cycles           |  901 ms  |  793 ms  | 1.14x faster | Significant (t=38.63)   |
| async_tree_none            |  532 ms  |  468 ms  | 1.14x faster | Significant (t=21.03)   |
| genshi_xml                 | 46.2 ms  | 41.0 ms  | 1.13x faster | Significant (t=47.10)   |
| genshi_text                | 20.7 ms  | 18.4 ms  | 1.13x faster | Significant (t=46.58)   |
| pyflate                    |  381 ms  |  337 ms  | 1.13x faster | Significant (t=20.83)   |
| bench_thread_pool          | 1.24 ms  | 1.12 ms  | 1.11x faster | Significant (t=59.33)   |
| deepcopy                   |  383 ms  |  345 ms  | 1.11x faster | Significant (t=49.52)   |
| python_startup             | 7.52 ms  | 6.76 ms  | 1.11x faster | Significant (t=17.69)   |
| 2to3                       |  231 ms  |  211 ms  | 1.10x faster | Significant (t=44.06)   |
| fannkuch                   |  314 ms  |  285 ms  | 1.10x faster | Significant (t=21.71)   |
| logging_silent             | 90.8 ns  | 82.7 ns  | 1.10x faster | Significant (t=20.61)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| sqlglot_normalize          |  107 ms  |  216 ms  | 2.01x slower | Significant (t=-156.63) |
| asyncio_tcp                |  967 ms  |  990 ms  | 1.02x slower | Significant (t=-3.00)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

### Debian package versus own package/image

```text
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| Benchmark                  | Debian   | [own]    | Change       | Significance           |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| tornado_http               |  168 ms  | 96.4 ms  | 1.75x faster | Significant (t=24.63)  |
| gc_traversal               | 3.51 ms  | 2.34 ms  | 1.50x faster | Significant (t=14.26)  |
| async_generators           |  342 ms  |  230 ms  | 1.49x faster | Significant (t=26.43)  |
| float                      | 86.2 ms  | 58.2 ms  | 1.48x faster | Significant (t=12.80)  |
| unpickle_pure_python       |  264 ms  |  183 ms  | 1.45x faster | Significant (t=11.80)  |
| xml_etree_iterparse        |  101 ms  | 73.0 ms  | 1.38x faster | Significant (t=13.47)  |
| xml_etree_generate         | 81.0 ms  | 59.4 ms  | 1.36x faster | Significant (t=10.56)  |
| coverage                   | 67.4 ms  | 50.5 ms  | 1.33x faster | Significant (t=93.77)  |
| unpickle_list              | 4.31 us  | 3.24 us  | 1.33x faster | Significant (t=11.26)  |
| create_gc_cycles           | 1.03 ms  |  793 ms  | 1.30x faster | Significant (t=9.48)   |
| 2to3                       |  273 ms  |  211 ms  | 1.30x faster | Significant (t=47.08)  |
| async_tree_none            |  608 ms  |  468 ms  | 1.30x faster | Significant (t=30.31)  |
| mdp                        | 2.68 sec | 2.06 sec | 1.30x faster | Significant (t=28.20)  |
| generators                 | 50.1 ms  | 38.8 ms  | 1.29x faster | Significant (t=12.90)  |
| unpickle                   | 12.7 us  | 9.86 us  | 1.28x faster | Significant (t=7.99)   |
| xml_etree_parse            |  146 ms  |  118 ms  | 1.24x faster | Significant (t=11.86)  |
| richards                   | 45.4 ms  | 37.0 ms  | 1.23x faster | Significant (t=37.28)  |
| richards_super             | 54.5 ms  | 45.5 ms  | 1.20x faster | Significant (t=53.79)  |
| hexiom                     | 6.05 ms  | 5.04 ms  | 1.20x faster | Significant (t=27.11)  |
| tomli_loads                | 1.94 sec | 1.62 sec | 1.20x faster | Significant (t=14.30)  |
| scimark_fft                |  226 ms  |  189 ms  | 1.19x faster | Significant (t=31.41)  |
| regex_effbot               | 2.65 ms  | 2.24 ms  | 1.18x faster | Significant (t=58.72)  |
| go                         |  138 ms  |  117 ms  | 1.18x faster | Significant (t=55.47)  |
| genshi_xml                 | 48.3 ms  | 41.0 ms  | 1.18x faster | Significant (t=12.37)  |
| dask                       |  491 ms  |  421 ms  | 1.17x faster | Significant (t=43.56)  |
| regex_dna                  |  146 ms  |  125 ms  | 1.16x faster | Significant (t=56.54)  |
| scimark_sparse_mat_mult    | 3.20 ms  | 2.76 ms  | 1.16x faster | Significant (t=47.15)  |
| async_tree_cpu_io_mixed    |  757 ms  |  654 ms  | 1.16x faster | Significant (t=12.89)  |
| sqlite_synth               | 2.19 us  | 1.90 us  | 1.15x faster | Significant (t=83.98)  |
| typing_runtime_protocols   |  423 ms  |  368 ms  | 1.15x faster | Significant (t=8.04)   |
| regex_compile              |  121 ms  |  105 ms  | 1.15x faster | Significant (t=71.96)  |
| unpack_sequence            | 35.5 ns  | 30.8 ns  | 1.15x faster | Significant (t=13.25)  |
| json_dumps                 | 9.95 ms  | 8.69 ms  | 1.14x faster | Significant (t=28.13)  |
| sqlglot_normalize          |  244 ms  |  216 ms  | 1.13x faster | Significant (t=64.02)  |
| sqlglot_optimize           | 45.4 ms  | 40.3 ms  | 1.13x faster | Significant (t=56.81)  |
| pathlib                    | 13.9 ms  | 12.3 ms  | 1.13x faster | Significant (t=11.90)  |
| genshi_text                | 20.6 ms  | 18.4 ms  | 1.12x faster | Significant (t=6.71)   |
| sqlglot_parse              | 1.21 ms  | 1.08 ms  | 1.12x faster | Significant (t=45.75)  |
| deepcopy_memo              | 30.1 us  | 26.9 us  | 1.12x faster | Significant (t=43.04)  |
| logging_format             | 8.40 us  | 7.52 us  | 1.12x faster | Significant (t=36.64)  |
| deepcopy_reduce            | 2.68 us  | 2.39 us  | 1.12x faster | Significant (t=26.92)  |
| regex_v8                   | 18.8 ms  | 16.8 ms  | 1.12x faster | Significant (t=10.48)  |
| docutils                   | 2.26 sec | 2.03 sec | 1.11x faster | Significant (t=21.20)  |
| sympy_integrate            | 17.7 ms  | 16.1 ms  | 1.10x faster | Significant (t=48.64)  |
| sympy_sum                  |  139 ms  |  127 ms  | 1.10x faster | Significant (t=46.13)  |
| scimark_monte_carlo        | 52.9 ms  | 48.2 ms  | 1.10x faster | Significant (t=40.64)  |
| async_tree_memoization     |  653 ms  |  592 ms  | 1.10x faster | Significant (t=18.97)  |
| pyflate                    |  370 ms  |  337 ms  | 1.10x faster | Significant (t=18.84)  |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| pickle_list                | 2.03 us  | 2.71 us  | 1.34x slower | Significant (t=-48.71) |
| pickle_dict                | 16.8 us  | 20.0 us  | 1.19x slower | Significant (t=-17.89) |
| nbody                      | 71.3 ms  | 82.6 ms  | 1.16x slower | Significant (t=-35.07) |
| pickle                     | 7.08 us  | 7.78 us  | 1.10x slower | Significant (t=-37.90) |
| coroutines                 | 21.6 ms  | 22.1 ms  | 1.02x slower | Significant (t=-7.24)  |
| comprehensions             | 17.8 us  | 17.9 us  | 1.01x slower | Not significant        |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

### official Docker image versus Debian package

```text
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| Benchmark                  | Docker   | Debian   | Change       | Significance            |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| pickle_list                | 4.23 us  | 2.03 us  | 2.09x faster | Significant (t=266.89)  |
| pickle_dict                | 30.5 us  | 16.8 us  | 1.81x faster | Significant (t=230.30)  |
| pickle                     | 11.9 us  | 7.08 us  | 1.68x faster | Significant (t=199.35)  |
| json_loads                 | 26.4 us  | 17.4 us  | 1.52x faster | Significant (t=106.19)  |
| scimark_sparse_mat_mult    | 4.69 ms  | 3.20 ms  | 1.47x faster | Significant (t=90.11)   |
| scimark_fft                |  328 ms  |  226 ms  | 1.45x faster | Significant (t=42.74)   |
| telco                      | 7.12 ms  | 4.97 ms  | 1.43x faster | Significant (t=104.81)  |
| spectral_norm              |  106 ms  | 77.1 ms  | 1.37x faster | Significant (t=82.59)   |
| typing_runtime_protocols   |  577 us  |  423 us  | 1.36x faster | Significant (t=21.13)   |
| regex_compile              |  159 ms  |  121 ms  | 1.32x faster | Significant (t=24.77)   |
| xml_etree_iterparse        |  132 ms  |  101 ms  | 1.32x faster | Significant (t=11.07)   |
| async_tree_memoization_tg  |  699 ms  |  536 ms  | 1.30x faster | Significant (t=13.05)   |
| xml_etree_parse            |  190 ms  |  146 ms  | 1.30x faster | Significant (t=10.30)   |
| async_tree_cpu_io_mixed_tg |  782 ms  |  608 ms  | 1.29x faster | Significant (t=20.89)   |
| raytrace                   |  317 ms  |  250 ms  | 1.27x faster | Significant (t=18.15)   |
| nbody                      | 89.5 ms  | 71.3 ms  | 1.26x faster | Significant (t=70.42)   |
| docutils                   | 2.86 sec | 2.26 sec | 1.26x faster | Significant (t=39.45)   |
| crypto_pyaes               | 70.2 ms  | 56.3 ms  | 1.25x faster | Significant (t=68.74)   |
| async_tree_memoization     |  816 ms  |  653 ms  | 1.25x faster | Significant (t=24.40)   |
| unpack_sequence            | 43.7 ns  | 35.5 ns  | 1.23x faster | Significant (t=16.08)   |
| pickle_pure_python         |  295 us  |  242 us  | 1.22x faster | Significant (t=84.14)   |
| async_tree_none_tg         |  494 ms  |  404 ms  | 1.22x faster | Significant (t=41.45)   |
| unpickle_list              | 5.22 us  | 4.31 us  | 1.21x faster | Significant (t=9.15)    |
| meteor_contest             | 98.0 ms  | 81.2 ms  | 1.21x faster | Significant (t=59.03)   |
| async_tree_io_tg           | 1.30 sec | 1.07 sec | 1.21x faster | Significant (t=14.19)   |
| scimark_lu                 |  103 ms  | 86.6 ms  | 1.19x faster | Significant (t=39.39)   |
| nqueens                    | 80.3 ms  | 67.9 ms  | 1.18x faster | Significant (t=62.04)   |
| chaos                      | 65.6 ms  | 56.3 ms  | 1.17x faster | Significant (t=50.99)   |
| sqlglot_transpile          | 1.66 ms  | 1.42 ms  | 1.17x faster | Significant (t=27.17)   |
| comprehensions             | 20.7 us  | 17.8 us  | 1.16x faster | Significant (t=43.45)   |
| scimark_sor                |  109 ms  | 93.6 ms  | 1.16x faster | Significant (t=42.46)   |
| scimark_monte_carlo        | 61.5 ms  | 52.9 ms  | 1.16x faster | Significant (t=42.08)   |
| xml_etree_process          | 55.0 ms  | 47.4 ms  | 1.16x faster | Significant (t=12.22)   |
| tomli_loads                | 2.22 sec | 1.94 sec | 1.14x faster | Significant (t=9.67)    |
| pprint_safe_repr           |  669 ms  |  589 ms  | 1.14x faster | Significant (t=36.56)   |
| sqlglot_parse              | 1.38 ms  | 1.21 ms  | 1.14x faster | Significant (t=28.66)   |
| chameleon                  | 6.11 ms  | 5.42 ms  | 1.13x faster | Significant (t=32.43)   |
| pidigits                   |  163 ms  |  145 ms  | 1.12x faster | Significant (t=80.97)   |
| regex_v8                   | 21.0 ms  | 18.8 ms  | 1.12x faster | Significant (t=8.89)    |
| pprint_pformat             | 1.39 sec | 1.23 sec | 1.12x faster | Significant (t=36.91)   |
| django_template            | 31.8 ms  | 28.4 ms  | 1.12x faster | Significant (t=34.50)   |
| sympy_expand               |  453 ms  |  406 ms  | 1.12x faster | Significant (t=24.66)   |
| sympy_integrate            | 19.9 ms  | 17.7 ms  | 1.12x faster | Significant (t=18.21)   |
| async_tree_io              | 1.32 sec | 1.19 sec | 1.11x faster | Significant (t=15.85)   |
| bench_mp_pool              | 34.2 ms  | 31.1 ms  | 1.10x faster | Significant (t=9.13)    |
| sympy_str                  |  271 ms  |  246 ms  | 1.10x faster | Significant (t=55.28)   |
| mako                       | 8.73 ms  | 7.93 ms  | 1.10x faster | Significant (t=19.71)   |
| regex_dna                  |  160 ms  |  146 ms  | 1.10x faster | Significant (t=12.43)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| sqlglot_normalize          |  107 ms  |  244 ms  | 2.27x slower | Significant (t=-191.09) |
| tornado_http               |  113 ms  |  168 ms  | 1.50x slower | Significant (t=-19.13)  |
| float                      | 70.9 ms  | 86.2 ms  | 1.22x slower | Significant (t=-6.98)   |
| 2to3                       |  231 ms  |  273 ms  | 1.18x slower | Significant (t=-31.74)  |
| async_generators           |  294 ms  |  342 ms  | 1.16x slower | Significant (t=-11.00)  |
| create_gc_cycles           |  901 us  | 1.03 ms  | 1.15x slower | Significant (t=-5.18)   |
| unpickle_pure_python       |  229 us  |  264 us  | 1.15x slower | Significant (t=-5.06)   |
| async_tree_none            |  532 ms  |  608 ms  | 1.14x slower | Significant (t=-14.20)  |
| gc_traversal               | 3.11 ms  | 3.51 ms  | 1.13x slower | Significant (t=-4.93)   |
| go                         |  123 ms  |  138 ms  | 1.12x slower | Significant (t=-37.32)  |
| asyncio_tcp                |  967 ms  | 1.06 sec | 1.10x slower | Significant (t=-11.46)  |
| genshi_xml                 | 46.2 ms  | 48.3 ms  | 1.05x slower | Significant (t=-3.54)   |
| richards                   | 44.1 ms  | 45.4 ms  | 1.03x slower | Significant (t=-4.15)   |
| xml_etree_generate         | 78.7 ms  | 81.0 ms  | 1.03x slower | Not significant         |
| hexiom                     | 5.92 ms  | 6.05 ms  | 1.02x slower | Significant (t=-3.73)   |
| html5lib                   | 60.0 ms  | 60.5 ms  | 1.01x slower | Not significant         |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
