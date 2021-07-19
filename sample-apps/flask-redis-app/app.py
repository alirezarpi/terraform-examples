import time, os
import socket

import redis
from flask import Flask, json, request
from flask_cors import CORS


version = os.environ.get("VERSION")
redis_host = os.environ.get("REDIS_HOST")
redis_port = os.environ.get("REDIS_PORT")

app = Flask(__name__)
CORS(app)


def connect_to_redis():
    cache = redis.Redis(host=redis_host, port=redis_port)
    return cache


def get_hit_count():
    retries = 5
    while True:
        try:
            return connect_to_redis().incr("hits")
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route("/")
def hostname_api():
    data = {"version": version, "hostname": socket.gethostname()}
    return app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype="application/json",
    )


@app.route("/cache/")
def cache_api():
    count = get_hit_count()
    data = {"version": version, "call_count": count}
    return app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype="application/json",
    )


@app.route("/health/")
def health_api():
    data = {"version": version, "state": "RUNNING"}
    return app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype="application/json",
    )


@app.route("/fail/")
def fail():
    func = request.environ.get("werkzeug.server.shutdown")
    if func is None:
        raise RuntimeError("Not running with Werkzeug Server")
    func()

    data = {"version": version, "state": "SHUTDOWN"}
    return app.response_class(
        response=json.dumps(data),
        status=503,
        mimetype="application/json",
    )
