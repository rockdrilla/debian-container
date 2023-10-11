# Python 3.11.6 benchmarks

Date: 11.10.2023

Reference: [`pyperformance`](https://github.com/python/pyperformance), commit ef1d636b

## Subjects

- official Docker image: docker.io/library/python:3.11.6-slim-bookworm
- own [package](../../package/python)/image: docker.io/rockdrilla/python:3.11.6-bookworm

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
| scimark_sparse_mat_mult    | 4.14 ms  | 2.47 ms  | 1.68x faster | Significant (t=90.38)  |
| pickle_list                | 4.00 us  | 2.51 us  | 1.60x faster | Significant (t=371.53) |
| pickle                     | 11.1 us  | 7.14 us  | 1.56x faster | Significant (t=134.58) |
| json_loads                 | 25.2 us  | 16.9 us  | 1.49x faster | Significant (t=328.93) |
| typing_runtime_protocols   |  543 us  |  364 us  | 1.49x faster | Significant (t=205.42) |
| scimark_fft                |  268 ms  |  181 ms  | 1.48x faster | Significant (t=177.06) |
| spectral_norm              | 93.1 ms  | 64.0 ms  | 1.46x faster | Significant (t=158.25) |
| pickle_dict                | 27.5 us  | 19.0 us  | 1.45x faster | Significant (t=512.32) |
| telco                      | 6.55 ms  | 4.68 ms  | 1.40x faster | Significant (t=203.63) |
| xml_etree_iterparse        | 90.6 ms  | 67.5 ms  | 1.34x faster | Significant (t=196.01) |
| async_generators           |  287 ms  |  215 ms  | 1.34x faster | Significant (t=138.62) |
| unpickle_list              | 4.56 us  | 3.46 us  | 1.32x faster | Significant (t=86.16)  |
| scimark_monte_carlo        | 58.9 ms  | 44.6 ms  | 1.32x faster | Significant (t=131.27) |
| crypto_pyaes               | 67.6 ms  | 52.5 ms  | 1.29x faster | Significant (t=99.95)  |
| chaos                      | 63.7 ms  | 49.5 ms  | 1.29x faster | Significant (t=90.33)  |
| generators                 | 47.2 ms  | 36.6 ms  | 1.29x faster | Significant (t=81.84)  |
| xml_etree_parse            |  137 ms  |  106 ms  | 1.29x faster | Significant (t=138.54) |
| meteor_contest             | 90.5 ms  | 70.9 ms  | 1.28x faster | Significant (t=232.71) |
| nqueens                    | 78.4 ms  | 61.8 ms  | 1.27x faster | Significant (t=48.51)  |
| coverage                   | 66.1 ms  | 51.9 ms  | 1.27x faster | Significant (t=128.67) |
| nbody                      | 87.6 ms  | 69.3 ms  | 1.26x faster | Significant (t=28.29)  |
| scimark_lu                 | 94.4 ms  | 75.3 ms  | 1.25x faster | Significant (t=92.70)  |
| float                      | 67.6 ms  | 54.3 ms  | 1.24x faster | Significant (t=89.87)  |
| scimark_sor                | 98.9 ms  | 80.0 ms  | 1.24x faster | Significant (t=56.15)  |
| mdp                        | 2.37 sec | 1.91 sec | 1.24x faster | Significant (t=46.21)  |
| raytrace                   |  273 ms  |  224 ms  | 1.22x faster | Significant (t=81.28)  |
| fannkuch                   |  314 ms  |  259 ms  | 1.21x faster | Significant (t=53.47)  |
| sqlglot_normalize          |  250 ms  |  208 ms  | 1.21x faster | Significant (t=140.68) |
| pickle_pure_python         |  272 us  |  224 us  | 1.21x faster | Significant (t=132.35) |
| regex_dna                  |  147 ms  |  121 ms  | 1.21x faster | Significant (t=101.56) |
| tomli_loads                | 1.90 sec | 1.59 sec | 1.20x faster | Significant (t=97.47)  |
| json_dumps                 | 10.3 ms  | 8.60 ms  | 1.20x faster | Significant (t=197.37) |
| pathlib                    | 14.4 ms  | 12.0 ms  | 1.20x faster | Significant (t=134.49) |
| unpickle                   | 12.1 us  | 10.1 us  | 1.20x faster | Significant (t=117.13) |
| hexiom                     | 5.71 ms  | 4.82 ms  | 1.19x faster | Significant (t=48.10)  |
| sqlglot_optimize           | 46.4 ms  | 38.9 ms  | 1.19x faster | Significant (t=167.65) |
| unpack_sequence            | 35.1 ns  | 29.7 ns  | 1.18x faster | Significant (t=31.40)  |
| regex_effbot               | 2.63 ms  | 2.23 ms  | 1.18x faster | Significant (t=106.14) |
| sqlglot_parse              | 1.24 ms  | 1.06 ms  | 1.17x faster | Significant (t=93.54)  |
| async_tree_cpu_io_mixed_tg |  666 ms  |  570 ms  | 1.17x faster | Significant (t=53.57)  |
| comprehensions             | 19.7 us  | 16.9 us  | 1.17x faster | Significant (t=105.76) |
| genshi_xml                 | 44.3 ms  | 38.2 ms  | 1.16x faster | Significant (t=88.06)  |
| deepcopy_reduce            | 2.77 us  | 2.39 us  | 1.16x faster | Significant (t=63.47)  |
| async_tree_memoization_tg  |  561 ms  |  485 ms  | 1.16x faster | Significant (t=26.88)  |
| sympy_str                  |  250 ms  |  215 ms  | 1.16x faster | Significant (t=146.79) |
| sympy_expand               |  410 ms  |  354 ms  | 1.16x faster | Significant (t=112.99) |
| sqlglot_transpile          | 1.48 ms  | 1.27 ms  | 1.16x faster | Significant (t=102.64) |
| xml_etree_process          | 45.5 ms  | 39.6 ms  | 1.15x faster | Significant (t=98.64)  |
| unpickle_pure_python       |  203 us  |  176 us  | 1.15x faster | Significant (t=85.81)  |
| docutils                   | 2.20 sec | 1.91 sec | 1.15x faster | Significant (t=68.60)  |
| django_template            | 30.2 ms  | 26.6 ms  | 1.14x faster | Significant (t=77.62)  |
| sqlalchemy_imperative      | 16.8 ms  | 14.7 ms  | 1.14x faster | Significant (t=74.41)  |
| deepcopy_memo              | 31.5 us  | 27.7 us  | 1.14x faster | Significant (t=54.40)  |
| tornado_http               |  104 ms  | 91.6 ms  | 1.14x faster | Significant (t=47.41)  |
| xml_etree_generate         | 64.7 ms  | 56.6 ms  | 1.14x faster | Significant (t=43.85)  |
| sympy_integrate            | 17.7 ms  | 15.6 ms  | 1.14x faster | Significant (t=138.62) |
| async_tree_io_tg           | 1.13 sec |  995 ms  | 1.14x faster | Significant (t=119.16) |
| regex_compile              |  116 ms  |  102 ms  | 1.14x faster | Significant (t=115.89) |
| sympy_sum                  |  141 ms  |  123 ms  | 1.14x faster | Significant (t=105.70) |
| pprint_safe_repr           |  609 ms  |  538 ms  | 1.13x faster | Significant (t=65.10)  |
| async_tree_none_tg         |  417 ms  |  368 ms  | 1.13x faster | Significant (t=114.44) |
| sqlite_synth               | 2.15 us  | 1.92 us  | 1.12x faster | Significant (t=89.12)  |
| pprint_pformat             | 1.26 sec | 1.13 sec | 1.12x faster | Significant (t=75.48)  |
| genshi_text                | 19.2 ms  | 17.2 ms  | 1.12x faster | Significant (t=43.35)  |
| sqlalchemy_declarative     |  105 ms  | 93.2 ms  | 1.12x faster | Significant (t=35.92)  |
| pyflate                    |  356 ms  |  319 ms  | 1.12x faster | Significant (t=35.78)  |
| richards                   | 38.6 ms  | 34.6 ms  | 1.12x faster | Significant (t=34.99)  |
| deltablue                  | 3.17 ms  | 2.84 ms  | 1.11x faster | Significant (t=95.72)  |
| deepcopy                   |  381 us  |  343 us  | 1.11x faster | Significant (t=72.52)  |
| 2to3                       |  233 ms  |  209 ms  | 1.11x faster | Significant (t=62.76)  |
| dulwich_log                | 62.8 ms  | 56.3 ms  | 1.11x faster | Significant (t=58.58)  |
| async_tree_none            |  505 ms  |  453 ms  | 1.11x faster | Significant (t=47.83)  |
| richards_super             | 48.7 ms  | 43.9 ms  | 1.11x faster | Significant (t=38.96)  |
| async_tree_cpu_io_mixed    |  725 ms  |  651 ms  | 1.11x faster | Significant (t=22.43)  |
| logging_simple             | 7.70 us  | 7.01 us  | 1.10x faster | Significant (t=83.95)  |
| logging_format             | 8.31 us  | 7.53 us  | 1.10x faster | Significant (t=83.71)  |
| async_tree_io              | 1.21 sec | 1.10 sec | 1.10x faster | Significant (t=37.78)  |
| logging_silent             | 84.0 ns  | 76.1 ns  | 1.10x faster | Significant (t=27.34)  |
| html5lib                   | 57.1 ms  | 51.7 ms  | 1.10x faster | Significant (t=19.62)  |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
| asyncio_tcp                |  769 ms  |  963 ms  | 1.25x slower | Significant (t=-88.94) |
| asyncio_tcp_ssl            | 1.95 sec | 2.03 sec | 1.04x slower | Significant (t=-20.02) |
| asyncio_websockets         |  502 ms  |  503 ms  | 1.00x slower | Not significant        |
| -------------------------- | -------- | -------- | ------------ | ---------------------- |
```

shell snippet:

  ```sh
  _pyperf_compare() { pyperformance compare -O table "$1" "$2" | grep "${3:-faster}" | sort -rk10 ; }

  pyperf_compare() { _pyperf_compare "$1" "$2" faster | mawk '$10 ~ "1\.0" {next} {print}' ; echo ; _pyperf_compare "$1" "$2" slower ; }
  ```
