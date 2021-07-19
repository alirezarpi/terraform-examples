# Flask Redis Sample Application

## Build

`$ docker build -t alirezarpi/flask-redis-app:latest .`

## Pull
`$ docker pull alirezarpi/flask-redis-app:latest`

## Run

`$ docker network create appnet`
`$ docker run --name flask-redis-app --rm --network appnet -p 5000:5000 -e VERSION="0.0.1" -e REDIS_HOST="redis" -e REDIS_PORT="6379" alirezarpi/flask-redis-app:latest`

### For running redis do
`$ docker run --network appnet --name redis -d redis:alpine`

----

## URLs

| URL        | What it does                               |
| ---------- | ------------------------------------------ |
| `/`        | version + hostname                         |
| `/cache/`  | version + redis calls (needs redis server) |
| `/health/` | version + state "RUNNING"                  |
| `/fail/`   | version + state "SHUTDOWN"                 |

---

## Nomad

`$ nomad job run ./cloud-configs/*`