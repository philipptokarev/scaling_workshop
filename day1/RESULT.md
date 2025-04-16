# CPU-bound

Результат нагрузного тестирования CPU показал, что масштабирование через
многопоточность или через работу с сокетами не уменьшит время обработки запроса сервером.
Для корректно масштабирования при нагрузках CPU необходимо увеличивать кол-во процессов.

## Sync(shell command: `exec ab -n 25000 -c 100 http://0.0.0.0:3000/cpu_bound/20`)
### Puma
| Workers | Theareds | Time |
| ------- | -------- | -----|
|    1    |    1:1   | 40.752 seconds |
|    1    |    1:4   | 39.811 seconds |
|    4    |    1:1   | 11.529 seconds |
|    4    |    1:4   | 11.737 seconds |

### Thin
|       Settings       | Time |
| -------------------- | ---- |
|       default        | 38.758 seconds |
|       threaded       | 40.271 seconds |
| threaded pool_size=4 | 40.591 seconds |

### Passenger
| Pool size | Time |
| --------- | ---- |
|     1     | 37.511 seconds |
|     4     | 13.488 seconds |

### Falcon
|    Type    |       Settings       | Time |
| ---------- | -------------------- | ---- |
|  threaded  |        count=1       | 40.534 seconds |
|  threaded  |        count=4       | 39.749 seconds |
|   hybrid   |  threades=4 forks=1  | 39.749 seconds |
|   hybrid   |  threades=1 forks=4  | 11.503 seconds |
|   hybrid   |  threades=4 forks=4  | 11.472 seconds |
|   forked   |        count=1       | 41.010 seconds |
|   forked   |        count=4       | 11.440 seconds |

## Async(shell command: `exec ab -n 25000 -c 100 http://0.0.0.0:3000/cpu_bound_async/20`)
### Puma
| Workers | Theareds | Time |
| ------- | -------- | -----|
|    1    |    1:1    | 40.270 seconds |
|    1    |    1:4    | 42.242 seconds |
|    4    |    1:1    | 12.867 seconds |
|    4    |    1:4    | 12.897 seconds |
### Thin
|       Settings       | Time |
| -------------------- | ---- |
|       default        | 39.017 seconds |
|       threaded       | 42.699 seconds |
| threaded pool_size=4 | 43.828 seconds |
### Passenger
| Pool size | Time |
| --------- | ---- |
|     1     | 38.130 seconds |
|     4     | 11.364 seconds |

# IO-bound

Результат нагрузного тестирования IO показал, что масштабирование через
многопоточность или через работу с сокетами сократит время обработки запроса сервером.
Также при увеличениии кол-ва процессов время обработки запроса сервером также уменьшиться,
что следует из [результата CPU-bound](#cpu-bound)).

## Sync(shell command: `exec ab -n 25000 -c 100 http://0.0.0.0:3000/io_bound`)
### Puma
| Workers | Theareds | Time |
| ------- | -------- | -----|
|    1    |    1:1   | 159.939 seconds |
|    1    |    1:4   | 84.569 seconds |
|    4    |    1:1   | 60.538 seconds |
|    4    |    1:4   | 42.640 seconds |
### Thin
|       Settings       | Time |
| -------------------- | ---- |
|       default        | 157.736 seconds |
|       threaded       | 75.870 seconds |
| threaded pool_size=4 | 79.666 seconds |
### Passenger
| Pool size | Time |
| --------- | ---- |
|     1     | 132.730 seconds |
|     4     | 47.578 seconds |
### Falcon
|    Type    |       Settings       | Time |
| ---------- | -------------------- | ---- |
|  threaded  |        count=1       | 158.298 seconds |
|  threaded  |        count=4       | 125.600 seconds |
|   hybrid   |  threades=4 forks=1  | 124.104 seconds |
|   hybrid   |  threades=1 forks=4  | 60.522 seconds |
|   hybrid   |  threades=4 forks=4  | 47.923 seconds |
|   forked   |        count=1       | 159.871 seconds |
|   forked   |        count=4       | 61.371 seconds |

## Async(shell command: `exec ab -n 25000 -c 100 http://0.0.0.0:3000/io_bound_async`)
### Puma
| Workers | Theareds | Time |
| ------- | -------- | -----|
|    1    |    1:1    | 75.801 seconds |
|    1    |    1:4    | 77.248 seconds |
|    4    |    1:1    | 39.319 seconds |
|    4    |    1:4    | 40.693 seconds |
### Thin
|       Settings       | Time |
| -------------------- | ---- |
|       default        | 77.308 seconds |
|       threaded       | 79.035 seconds |
| threaded pool_size=4 | 77.715 seconds |
### Passenger
| Pool size | Time |
| --------- | ---- |
|     1     | 138.209 seconds |
|     4     | 50.372 seconds |
