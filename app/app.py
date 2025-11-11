from flask import Flask, render_template, jsonify, request

app = Flask(__name__)

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/api/ping")
def ping():
    return jsonify({"ok": True, "msg": "pong"})

@app.route("/api/feedback", methods=["POST"])
def feedback():
    data = request.get_json(force=True, silent=True) or {}
    name = data.get("name", "Anonymous")
    message = data.get("message", "")
    return jsonify({"saved": True, "name": name, "message": message})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
