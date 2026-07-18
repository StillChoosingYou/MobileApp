from flask import Blueprint, jsonify

from db import get_connection

catalog_bp = Blueprint("catalog", __name__)

# These two routes intentionally skip @token_required — announcements and
# the subject catalog aren't student-specific or sensitive. Add the
# decorator back (see routes/student.py for the pattern) if your school
# wants these gated behind login too.


@catalog_bp.route("/announcements", methods=["GET"])
def get_announcements():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM announcements ORDER BY posted_at DESC LIMIT 50")
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify(
        [
            {
                "id": r["id"],
                "title": r["title"],
                "body": r["body"],
                "category": r["category"],
                "postedAt": r["posted_at"].isoformat(),
            }
            for r in rows
        ]
    )


@catalog_bp.route("/subjects", methods=["GET"])
def get_subjects():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM subjects")
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify(
        [
            {
                "code": r["code"],
                "title": r["title"],
                "units": float(r["units"]),
                "prerequisites": r["prerequisites"],
                "isElective": r["is_elective"],
            }
            for r in rows
        ]
    )
