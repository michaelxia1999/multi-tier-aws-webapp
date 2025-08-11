from flask import Flask  # type: ignore
import os
import requests  # type: ignore

PRIVATE_API = os.environ["PRIVATE_API"]
INSTANCE_ID = os.environ["INSTANCE_ID"]


app = Flask(__name__)


@app.route("/")
def index():
    res = requests.get(PRIVATE_API, timeout=2)
    data = res.json().get("data")
    return f"<h1>{data}! This is Instance {INSTANCE_ID}</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
