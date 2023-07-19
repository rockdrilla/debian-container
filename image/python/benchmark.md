# Python 3.11.4 benchmarks

Date: 19.07.2023

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
| xml_etree_iterparse        |  132 ms  | 71.4 ms  | 1.85x faster | Significant (t=29.74)   |
| scimark_sparse_mat_mult    | 4.69 ms  | 2.55 ms  | 1.84x faster | Significant (t=78.55)   |
| scimark_fft                |  328 ms  |  182 ms  | 1.81x faster | Significant (t=59.47)   |
| unpickle_list              | 5.22 us  | 3.11 us  | 1.68x faster | Significant (t=62.60)   |
| typing_runtime_protocols   |  577 us  |  356 us  | 1.62x faster | Significant (t=85.35)   |
| xml_etree_parse            |  190 ms  |  117 ms  | 1.62x faster | Significant (t=20.28)   |
| json_loads                 | 26.4 us  | 16.4 us  | 1.61x faster | Significant (t=140.67)  |
| sqlalchemy_imperative      | 24.1 ms  | 15.2 ms  | 1.59x faster | Significant (t=29.03)   |
| pickle_dict                | 30.5 us  | 19.3 us  | 1.58x faster | Significant (t=199.08)  |
| pickle_list                | 4.23 us  | 2.73 us  | 1.55x faster | Significant (t=178.56)  |
| pickle                     | 11.9 us  | 7.68 us  | 1.55x faster | Significant (t=162.23)  |
| regex_compile              |  159 ms  |  104 ms  | 1.54x faster | Significant (t=35.98)   |
| mdp                        | 2.91 sec | 1.90 sec | 1.53x faster | Significant (t=36.24)   |
| telco                      | 7.12 ms  | 4.67 ms  | 1.52x faster | Significant (t=128.15)  |
| spectral_norm              |  106 ms  | 71.0 ms  | 1.49x faster | Significant (t=103.27)  |
| docutils                   | 2.86 sec | 1.92 sec | 1.48x faster | Significant (t=65.35)   |
| regex_dna                  |  160 ms  |  112 ms  | 1.43x faster | Significant (t=43.05)   |
| unpack_sequence            | 43.7 ns  | 30.8 ns  | 1.42x faster | Significant (t=30.88)   |
| unpickle                   | 13.4 us  | 9.47 us  | 1.41x faster | Significant (t=47.15)   |
| xml_etree_generate         | 78.7 ms  | 55.6 ms  | 1.41x faster | Significant (t=38.81)   |
| raytrace                   |  317 ms  |  225 ms  | 1.41x faster | Significant (t=25.19)   |
| async_tree_memoization_tg  |  699 ms  |  495 ms  | 1.41x faster | Significant (t=16.33)   |
| async_tree_cpu_io_mixed_tg |  782 ms  |  566 ms  | 1.38x faster | Significant (t=26.11)   |
| async_generators           |  294 ms  |  214 ms  | 1.37x faster | Significant (t=71.81)   |
| generators                 | 51.5 ms  | 38.0 ms  | 1.36x faster | Significant (t=72.94)   |
| async_tree_memoization     |  816 ms  |  599 ms  | 1.36x faster | Significant (t=33.05)   |
| tomli_loads                | 2.22 sec | 1.62 sec | 1.36x faster | Significant (t=30.76)   |
| xml_etree_process          | 55.0 ms  | 40.6 ms  | 1.35x faster | Significant (t=40.94)   |
| scimark_lu                 |  103 ms  | 76.8 ms  | 1.34x faster | Significant (t=65.82)   |
| meteor_contest             | 98.0 ms  | 73.5 ms  | 1.33x faster | Significant (t=105.46)  |
| scimark_monte_carlo        | 61.5 ms  | 46.6 ms  | 1.32x faster | Significant (t=69.25)   |
| regex_effbot               | 2.87 ms  | 2.17 ms  | 1.32x faster | Significant (t=40.90)   |
| unpickle_pure_python       |  229 us  |  175 us  | 1.31x faster | Significant (t=57.87)   |
| async_tree_none_tg         |  494 ms  |  377 ms  | 1.31x faster | Significant (t=55.61)   |
| gc_traversal               | 3.11 ms  | 2.37 ms  | 1.31x faster | Significant (t=37.64)   |
| chaos                      | 65.6 ms  | 50.7 ms  | 1.30x faster | Significant (t=124.01)  |
| pickle_pure_python         |  295 us  |  228 us  | 1.29x faster | Significant (t=86.22)   |
| coverage                   | 69.1 ms  | 53.5 ms  | 1.29x faster | Significant (t=81.10)   |
| sqlalchemy_declarative     |  122 ms  | 94.6 ms  | 1.29x faster | Significant (t=59.70)   |
| async_tree_io_tg           | 1.30 sec | 1.01 sec | 1.29x faster | Significant (t=18.73)   |
| sqlglot_transpile          | 1.66 ms  | 1.30 ms  | 1.28x faster | Significant (t=42.74)   |
| nbody                      | 89.5 ms  | 70.2 ms  | 1.28x faster | Significant (t=33.85)   |
| regex_v8                   | 21.0 ms  | 16.4 ms  | 1.28x faster | Significant (t=29.16)   |
| crypto_pyaes               | 70.2 ms  | 55.5 ms  | 1.27x faster | Significant (t=96.33)   |
| float                      | 70.9 ms  | 55.6 ms  | 1.27x faster | Significant (t=85.93)   |
| sqlglot_parse              | 1.38 ms  | 1.08 ms  | 1.27x faster | Significant (t=53.42)   |
| async_tree_cpu_io_mixed    |  809 ms  |  638 ms  | 1.27x faster | Significant (t=22.09)   |
| json_dumps                 | 10.8 ms  | 8.52 ms  | 1.27x faster | Significant (t=104.68)  |
| sympy_integrate            | 19.9 ms  | 15.8 ms  | 1.26x faster | Significant (t=34.67)   |
| nqueens                    | 80.3 ms  | 63.9 ms  | 1.26x faster | Significant (t=124.66)  |
| scimark_sor                |  109 ms  | 86.4 ms  | 1.26x faster | Significant (t=12.79)   |
| sympy_expand               |  453 ms  |  363 ms  | 1.25x faster | Significant (t=52.83)   |
| sqlglot_optimize           | 48.9 ms  | 39.1 ms  | 1.25x faster | Significant (t=110.47)  |
| hexiom                     | 5.92 ms  | 4.77 ms  | 1.24x faster | Significant (t=99.18)   |
| pathlib                    | 15.0 ms  | 12.1 ms  | 1.24x faster | Significant (t=96.60)   |
| pprint_safe_repr           |  669 ms  |  540 ms  | 1.24x faster | Significant (t=86.26)   |
| pprint_pformat             | 1.39 sec | 1.12 sec | 1.24x faster | Significant (t=100.58)  |
| sqlite_synth               | 2.40 us  | 1.95 us  | 1.23x faster | Significant (t=44.07)   |
| django_template            | 31.8 ms  | 26.1 ms  | 1.22x faster | Significant (t=64.75)   |
| sympy_sum                  |  152 ms  |  126 ms  | 1.21x faster | Significant (t=70.74)   |
| comprehensions             | 20.7 us  | 17.1 us  | 1.21x faster | Significant (t=57.42)   |
| richards_super             | 56.1 ms  | 46.3 ms  | 1.21x faster | Significant (t=24.19)   |
| sympy_str                  |  271 ms  |  225 ms  | 1.20x faster | Significant (t=78.39)   |
| chameleon                  | 6.11 ms  | 5.08 ms  | 1.20x faster | Significant (t=59.47)   |
| dulwich_log                | 68.4 ms  | 57.5 ms  | 1.19x faster | Significant (t=52.90)   |
| python_startup_no_site     | 5.57 ms  | 4.70 ms  | 1.19x faster | Significant (t=40.85)   |
| pyflate                    |  381 ms  |  321 ms  | 1.19x faster | Significant (t=33.42)   |
| async_tree_io              | 1.32 sec | 1.11 sec | 1.19x faster | Significant (t=25.70)   |
| pidigits                   |  163 ms  |  136 ms  | 1.19x faster | Significant (t=122.70)  |
| genshi_xml                 | 46.2 ms  | 39.2 ms  | 1.18x faster | Significant (t=68.17)   |
| genshi_text                | 20.7 ms  | 17.6 ms  | 1.18x faster | Significant (t=62.93)   |
| mako                       | 8.73 ms  | 7.40 ms  | 1.18x faster | Significant (t=34.87)   |
| deepcopy_memo              | 32.9 us  | 27.9 us  | 1.18x faster | Significant (t=27.13)   |
| async_tree_none            |  532 ms  |  452 ms  | 1.18x faster | Significant (t=26.89)   |
| bench_mp_pool              | 34.2 ms  | 29.0 ms  | 1.18x faster | Significant (t=17.98)   |
| logging_format             | 8.78 us  | 7.53 us  | 1.17x faster | Significant (t=61.74)   |
| deltablue                  | 3.41 ms  | 2.93 ms  | 1.17x faster | Significant (t=47.77)   |
| deepcopy_reduce            | 2.85 us  | 2.43 us  | 1.17x faster | Significant (t=41.18)   |
| fannkuch                   |  314 ms  |  268 ms  | 1.17x faster | Significant (t=35.33)   |
| tornado_http               |  113 ms  | 97.4 ms  | 1.16x faster | Significant (t=34.49)   |
| richards                   | 44.1 ms  | 37.9 ms  | 1.16x faster | Significant (t=19.79)   |
| logging_simple             | 8.06 us  | 6.99 us  | 1.15x faster | Significant (t=62.79)   |
| create_gc_cycles           |  901 us  |  787 us  | 1.15x faster | Significant (t=39.07)   |
| dask                       |  519 ms  |  456 ms  | 1.14x faster | Significant (t=30.36)   |
| deepcopy                   |  383 us  |  342 us  | 1.12x faster | Significant (t=92.77)   |
| 2to3                       |  231 ms  |  206 ms  | 1.12x faster | Significant (t=61.71)   |
| python_startup             | 7.52 ms  | 6.72 ms  | 1.12x faster | Significant (t=20.35)   |
| logging_silent             | 90.8 ns  | 80.8 ns  | 1.12x faster | Significant (t=17.44)   |
| html5lib                   | 60.0 ms  | 53.3 ms  | 1.12x faster | Significant (t=17.40)   |
| bench_thread_pool          | 1.24 ms  | 1.12 ms  | 1.11x faster | Significant (t=63.12)   |
| coroutines                 | 22.9 ms  | 20.7 ms  | 1.11x faster | Significant (t=24.58)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| sqlglot_normalize          |  107 ms  |  207 ms  | 1.93x slower | Significant (t=-153.98) |
| asyncio_tcp                |  967 ms  |  995 ms  | 1.03x slower | Significant (t=-3.64)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
```

### Debian package versus own package/image

```text
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| Benchmark                  | Debian   | [own]    | Change       | Significance            |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| tornado_http               |  168 ms  | 97.4 ms  | 1.73x faster | Significant (t=24.37)   |
| async_generators           |  342 ms  |  214 ms  | 1.60x faster | Significant (t=30.25)   |
| float                      | 86.2 ms  | 55.6 ms  | 1.55x faster | Significant (t=13.96)   |
| unpickle_pure_python       |  264 us  |  175 us  | 1.51x faster | Significant (t=12.96)   |
| gc_traversal               | 3.51 ms  | 2.37 ms  | 1.48x faster | Significant (t=13.88)   |
| xml_etree_generate         | 81.0 ms  | 55.6 ms  | 1.46x faster | Significant (t=12.49)   |
| mdp                        | 2.68 sec | 1.90 sec | 1.41x faster | Significant (t=47.18)   |
| xml_etree_iterparse        |  101 ms  | 71.4 ms  | 1.41x faster | Significant (t=14.23)   |
| unpickle_list              | 4.31 us  | 3.11 us  | 1.39x faster | Significant (t=12.67)   |
| async_tree_none            |  608 ms  |  452 ms  | 1.35x faster | Significant (t=34.13)   |
| unpickle                   | 12.7 us  | 9.47 us  | 1.34x faster | Significant (t=9.10)    |
| 2to3                       |  273 ms  |  206 ms  | 1.32x faster | Significant (t=51.02)   |
| generators                 | 50.1 ms  | 38.0 ms  | 1.32x faster | Significant (t=13.92)   |
| create_gc_cycles           | 1.03 ms  |  787 us  | 1.31x faster | Significant (t=9.71)    |
| regex_dna                  |  146 ms  |  112 ms  | 1.30x faster | Significant (t=80.16)   |
| hexiom                     | 6.05 ms  | 4.77 ms  | 1.27x faster | Significant (t=37.17)   |
| coverage                   | 67.4 ms  | 53.5 ms  | 1.26x faster | Significant (t=71.11)   |
| scimark_sparse_mat_mult    | 3.20 ms  | 2.55 ms  | 1.25x faster | Significant (t=26.35)   |
| scimark_fft                |  226 ms  |  182 ms  | 1.24x faster | Significant (t=59.36)   |
| xml_etree_parse            |  146 ms  |  117 ms  | 1.24x faster | Significant (t=12.21)   |
| genshi_xml                 | 48.3 ms  | 39.2 ms  | 1.23x faster | Significant (t=15.45)   |
| regex_effbot               | 2.65 ms  | 2.17 ms  | 1.22x faster | Significant (t=43.50)   |
| go                         |  138 ms  |  115 ms  | 1.20x faster | Significant (t=62.10)   |
| richards                   | 45.4 ms  | 37.9 ms  | 1.20x faster | Significant (t=29.87)   |
| typing_runtime_protocols   |  423 us  |  356 us  | 1.19x faster | Significant (t=9.85)    |
| async_tree_cpu_io_mixed    |  757 ms  |  638 ms  | 1.19x faster | Significant (t=15.46)   |
| tomli_loads                | 1.94 sec | 1.62 sec | 1.19x faster | Significant (t=14.68)   |
| richards_super             | 54.5 ms  | 46.3 ms  | 1.18x faster | Significant (t=47.34)   |
| sqlglot_normalize          |  244 ms  |  207 ms  | 1.18x faster | Significant (t=102.40)  |
| genshi_text                | 20.6 ms  | 17.6 ms  | 1.17x faster | Significant (t=9.00)    |
| regex_compile              |  121 ms  |  104 ms  | 1.17x faster | Significant (t=82.98)   |
| docutils                   | 2.26 sec | 1.92 sec | 1.17x faster | Significant (t=51.38)   |
| json_dumps                 | 9.95 ms  | 8.52 ms  | 1.17x faster | Significant (t=33.43)   |
| xml_etree_process          | 47.4 ms  | 40.6 ms  | 1.17x faster | Significant (t=13.06)   |
| sqlglot_optimize           | 45.4 ms  | 39.1 ms  | 1.16x faster | Significant (t=68.73)   |
| pyflate                    |  370 ms  |  321 ms  | 1.15x faster | Significant (t=36.30)   |
| pathlib                    | 13.9 ms  | 12.1 ms  | 1.15x faster | Significant (t=13.60)   |
| regex_v8                   | 18.8 ms  | 16.4 ms  | 1.15x faster | Significant (t=12.60)   |
| unpack_sequence            | 35.5 ns  | 30.8 ns  | 1.15x faster | Significant (t=12.35)   |
| scimark_monte_carlo        | 52.9 ms  | 46.6 ms  | 1.14x faster | Significant (t=43.28)   |
| html5lib                   | 60.5 ms  | 53.3 ms  | 1.14x faster | Significant (t=15.37)   |
| sqlite_synth               | 2.19 us  | 1.95 us  | 1.13x faster | Significant (t=72.11)   |
| scimark_lu                 | 86.6 ms  | 76.8 ms  | 1.13x faster | Significant (t=49.16)   |
| sympy_integrate            | 17.7 ms  | 15.8 ms  | 1.12x faster | Significant (t=56.55)   |
| fannkuch                   |  299 ms  |  268 ms  | 1.12x faster | Significant (t=5.39)    |
| sympy_expand               |  406 ms  |  363 ms  | 1.12x faster | Significant (t=42.78)   |
| sqlglot_parse              | 1.21 ms  | 1.08 ms  | 1.12x faster | Significant (t=41.42)   |
| logging_format             | 8.40 us  | 7.53 us  | 1.12x faster | Significant (t=34.51)   |
| raytrace                   |  250 ms  |  225 ms  | 1.11x faster | Significant (t=43.52)   |
| chaos                      | 56.3 ms  | 50.7 ms  | 1.11x faster | Significant (t=32.83)   |
| python_startup_no_site     | 5.19 ms  | 4.70 ms  | 1.10x faster | Significant (t=44.63)   |
| meteor_contest             | 81.2 ms  | 73.5 ms  | 1.10x faster | Significant (t=41.34)   |
| sympy_sum                  |  139 ms  |  126 ms  | 1.10x faster | Significant (t=36.21)   |
| logging_simple             | 7.71 us  | 6.99 us  | 1.10x faster | Significant (t=33.29)   |
| pprint_pformat             | 1.23 sec | 1.12 sec | 1.10x faster | Significant (t=33.03)   |
| deepcopy_reduce            | 2.68 us  | 2.43 us  | 1.10x faster | Significant (t=23.22)   |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
| pickle_list                | 2.03 us  | 2.73 us  | 1.35x slower | Significant (t=-162.31) |
| pickle_dict                | 16.8 us  | 19.3 us  | 1.14x slower | Significant (t=-71.32)  |
| pickle                     | 7.08 us  | 7.68 us  | 1.08x slower | Significant (t=-23.19)  |
| -------------------------- | -------- | -------- | ------------ | ----------------------- |
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
