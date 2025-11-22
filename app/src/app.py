from flask import Flask, jsonify, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST, CollectorRegistry, multiprocess, Summary
import time
import os

app = Flask(__name__)

# Simple counter metric
REQUEST_COUNTER = Counter("myapp_requests_total", "Total number of requests")

# Optional example custom metric
REQUEST_LATENCY = Summary("myapp_request_latency_seconds", "Latency per request")

@app.route("/")
def index():
    REQUEST_COUNTER.inc()
    return jsonify({
        "status": "ok",
        "message": "Hello from DevOps interview sample app",
        "time": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    })

@app.route("/health")
def health():
    # liveness probe - simple 200
    return "ok", 200

@app.route("/ready")
def ready():
    # readiness check - we return ready if env variable READY is not 'false'
    ready_flag = os.environ.get("APP_READY", "true").lower()
    if ready_flag in ("0", "false", "no"):
        return "not ready", 503
    return "ready", 200

@app.route("/metrics")
def metrics():
    # Expose prometheus metrics in text format
    data = generate_latest()
    return Response(data, mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    # For local dev only (not for production)
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
