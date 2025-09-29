from flask import Flask  # type: ignore
import os
import requests  # type: ignore

PRIVATE_API = os.environ["PRIVATE_API"]
INSTANCE_ID = os.environ["INSTANCE_ID"]


app = Flask(__name__)


@app.route("/")
def index():
    res = requests.get(PRIVATE_API, timeout=2)
    message = res.json().get("message")
    return f"<h1>{message}! This is Instance {INSTANCE_ID}</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
