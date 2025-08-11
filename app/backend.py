from flask import Flask, jsonify  # type: ignore
import os
import boto3  # type: ignore

BUCKET = os.environ["BUCKET"]
KEY = os.environ["KEY"]

app = Flask(__name__)
s3 = boto3.client("s3")


@app.route("/")
def index():
    obj = s3.get_object(Bucket=BUCKET, Key=KEY)
    body = obj["Body"].read().decode("utf-8").strip()
    return jsonify({"data": body})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
