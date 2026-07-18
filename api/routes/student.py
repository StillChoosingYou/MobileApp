from flask import Blueprint, jsonify, request

from auth_utils import token_required
from db import get_connection

student_bp = Blueprint("student", __name__)


@student_bp.route("/<student_id>/profile", methods=["GET"])
@token_required
def get_profile(student_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM student_profiles WHERE student_id = %s", (student_id,))
            row = cur.fetchone()
    finally:
        conn.close()

    if row is None:
        return jsonify(None)

    return jsonify(
        {
            "studentId": row["student_id"],
            "program": row["program"],
            "yearLevel": row["year_level"],
            "blockSection": row["block_section"],
            "scholarshipLabel": row["scholarship_label"],
        }
    )


@student_bp.route("/<student_id>/sections", methods=["GET"])
@token_required
def get_sections(student_id):
    term = request.args.get("term")

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT section_ids FROM enrollments WHERE student_id = %s AND term = %s",
                (student_id, term),
            )
            enrollment = cur.fetchone()
            if enrollment is None or not enrollment["section_ids"]:
                return jsonify([])

            cur.execute("SELECT * FROM sections WHERE id = ANY(%s)", (enrollment["section_ids"],))
            sections = cur.fetchall()
    finally:
        conn.close()

    return jsonify(
        [
            {
                "id": s["id"],
                "subjectCode": s["subject_code"],
                "sectionLabel": s["section_label"],
                "facultyName": s["faculty_name"],
                "dayPattern": s["day_pattern"],
                "startTime": s["start_time"],
                "endTime": s["end_time"],
                "room": s["room"],
                "slotsTotal": s["slots_total"],
                "slotsTaken": s["slots_taken"],
            }
            for s in sections
        ]
    )


@student_bp.route("/<student_id>/grades", methods=["GET"])
@token_required
def get_grades(student_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM grades WHERE student_id = %s", (student_id,))
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify(
        [
            {
                "subjectCode": r["subject_code"],
                "subjectTitle": r["subject_title"],
                "units": float(r["units"]),
                "term": r["term"],
                "numericGrade": float(r["numeric_grade"]) if r["numeric_grade"] is not None else None,
                "isIncomplete": r["is_incomplete"],
            }
            for r in rows
        ]
    )


@student_bp.route("/<student_id>/ledger", methods=["GET"])
@token_required
def get_ledger(student_id):
    term = request.args.get("term")

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM ledgers WHERE student_id = %s AND term = %s",
                (student_id, term),
            )
            row = cur.fetchone()
    finally:
        conn.close()

    if row is None:
        return jsonify(
            {
                "studentId": student_id,
                "term": term,
                "tuitionFee": 0,
                "miscFees": 0,
                "labFees": 0,
                "scholarshipDiscount": 0,
                "totalPaid": 0,
            }
        )

    return jsonify(
        {
            "studentId": row["student_id"],
            "term": row["term"],
            "tuitionFee": float(row["tuition_fee"]),
            "miscFees": float(row["misc_fees"]),
            "labFees": float(row["lab_fees"]),
            "scholarshipDiscount": float(row["scholarship_discount"]),
            "totalPaid": float(row["total_paid"]),
        }
    )


@student_bp.route("/<student_id>/payments", methods=["GET"])
@token_required
def get_payments(student_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM payments WHERE student_id = %s ORDER BY timestamp DESC",
                (student_id,),
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify([_payment_row_to_json(r) for r in rows])


def _payment_row_to_json(r):
    return {
        "id": r["id"],
        "studentId": r["student_id"],
        "studentName": r["student_name"],
        "amount": float(r["amount"]),
        "method": r["method"],
        "receiptNumber": r["receipt_number"],
        "timestamp": r["timestamp"].isoformat(),
        "recordedBy": r["recorded_by"],
        "status": r["status"],
        "gatewayReference": r["gateway_reference"],
    }


@student_bp.route("/<student_id>/enrollment", methods=["GET"])
@token_required
def get_enrollment(student_id):
    term = request.args.get("term")

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM enrollments WHERE student_id = %s AND term = %s",
                (student_id, term),
            )
            row = cur.fetchone()
    finally:
        conn.close()

    if row is None:
        return jsonify(None)

    return jsonify(
        {
            "id": row["id"],
            "studentId": row["student_id"],
            "term": row["term"],
            "sectionIds": row["section_ids"],
            "status": row["status"],
            "remarks": row["remarks"],
        }
    )


@student_bp.route("/<student_id>/notifications", methods=["GET"])
@token_required
def get_notifications(student_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM notifications WHERE student_id = %s ORDER BY timestamp DESC",
                (student_id,),
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify(
        [
            {
                "id": r["id"],
                "title": r["title"],
                "body": r["body"],
                "timestamp": r["timestamp"].isoformat(),
                "read": r["read"],
            }
            for r in rows
        ]
    )
