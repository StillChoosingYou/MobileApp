import os
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

DB_URL = os.environ.get('DB_URL')
DB_PASSWORD = os.environ.get('DB_PASSWORD')


def get_db_connection():
    return psycopg2.connect(DB_URL)


@app.route('/')
def home():
    return jsonify({"status": "PGPC backend is running"})


@app.route('/api/health')
def health_check():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return jsonify({"status": "ok", "db": "connected"})
    except Exception as e:
        return jsonify({"status": "error", "db": str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True)