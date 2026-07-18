"""
PGPC Campus API — Flask + Postgres (Supabase) backend for the Flutter app.

Local development:
    python -m venv .venv && source .venv/bin/activate   # Windows: .venv\\Scripts\\activate
    pip install -r requirements.txt
    cp .env.example .env   # then fill in DATABASE_URL and JWT_SECRET
    python api/main.py
    # → serves on http://localhost:5000

Deploying (Vercel):
    Vercel auto-detects the `app` object below because this file is named
    `main.py` inside `api/` — one of its supported entrypoints. No custom
    build config needed beyond `vercel.json`'s `functions` block (already
    set up at the project root) and the DATABASE_URL / JWT_SECRET
    environment variables set in your Vercel project settings.
    See: https://vercel.com/docs/frameworks/backend/flask
"""

from flask import Flask, jsonify
from flask_cors import CORS

from routes.auth import auth_bp
from routes.cashier import cashier_bp
from routes.catalog import catalog_bp
from routes.student import student_bp

app = Flask(__name__)

# Permissive by default so local development (and Flutter Web, if you build
# it) isn't blocked by CORS while you're getting this running. Lock this
# down to your actual app's origin(s) before this handles real student data
# — see https://flask-cors.readthedocs.io/en/latest/api.html#extension
CORS(app)

app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(student_bp, url_prefix="/api/student")
app.register_blueprint(cashier_bp, url_prefix="/api/cashier")
app.register_blueprint(catalog_bp, url_prefix="/api")


@app.route("/api/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    # Local dev only — Vercel imports and calls the `app` object directly,
    # it never runs this block.
    app.run(debug=True, port=5000)
