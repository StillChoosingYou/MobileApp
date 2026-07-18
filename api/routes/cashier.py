import uuid
from datetime import date as date_cls
from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

from auth_utils import token_required
from db import get_connection

cashier_bp = Blueprint("cashier", __name__)

# NOTE ON AUTHORIZATION: `@token_required` below only checks that the caller
# has ANY valid PGPC login — it does not check they're logged in as a
# Cashier specifically. Before this handles real students' money, add a
# role check at the top of record_payment(), e.g.:
#
#   if request.auth_user["role"] != "cashier":
#       return jsonify({"error": "Forbidden."}), 403
#
# Left out for now only so every authenticated demo user can try the flow
# while you're still building — don't ship it this way.


def _next_receipt_number(cur):
    cur.execute("SELECT COUNT(*) AS n FROM payments")
    n = cur.fetchone()["n"]
    return f"OR-{datetime.now().year}-{(n + 1046):05d}"


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


@cashier_bp.route("/payments", methods=["POST"])
@token_required
def record_payment():
    data = request.get_json(silent=True) or {}
    student_id = data.get("studentId")
    student_name = data.get("studentName")
    amount = data.get("amount")
    method = data.get("method")
    recorded_by = data.get("recordedBy", "Cashier")

    if not student_id or not student_name or amount is None or not method:
        return jsonify({"error": "studentId, studentName, amount, and method are required."}), 400
    if amount <= 0:
        return jsonify({"error": "Amount must be greater than zero."}), 400

    payment_id = f"pay_{uuid.uuid4().hex[:12]}"

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            receipt_number = _next_receipt_number(cur)

            cur.execute(
                """
                INSERT INTO payments (id, student_id, student_name, amount, method,
                                       receipt_number, recorded_by, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'verified')
                """,
                (payment_id, student_id, student_name, amount, method, receipt_number, recorded_by),
            )

            # Applies to whichever term ledger row the student currently
            # has. If they have none yet, this UPDATE simply affects zero
            # rows — create the ledger row first (e.g. during enrollment)
            # if you need the payment to always land somewhere.
            cur.execute(
                "UPDATE ledgers SET total_paid = total_paid + %s WHERE student_id = %s",
                (amount, student_id),
            )

            cur.execute(
                "INSERT INTO audit_log (id, actor, action, target) VALUES (%s, %s, %s, %s)",
                (
                    f"log_{uuid.uuid4().hex[:12]}",
                    recorded_by,
                    "Recorded payment",
                    f"{receipt_number} — PHP {amount:.2f} ({method})",
                ),
            )

        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return jsonify(
        {
            "id": payment_id,
            "studentId": student_id,
            "studentName": student_name,
            "amount": float(amount),
            "method": method,
            "receiptNumber": receipt_number,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "recordedBy": recorded_by,
            "status": "verified",
            "gatewayReference": None,
        }
    )


@cashier_bp.route("/transactions", methods=["GET"])
@token_required
def get_transactions():
    on_date = request.args.get("date")  # "YYYY-MM-DD", optional

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            if on_date:
                cur.execute(
                    "SELECT * FROM payments WHERE timestamp::date = %s ORDER BY timestamp DESC",
                    (on_date,),
                )
            else:
                cur.execute("SELECT * FROM payments ORDER BY timestamp DESC")
            rows = cur.fetchall()
    finally:
        conn.close()

    return jsonify([_payment_row_to_json(r) for r in rows])


@cashier_bp.route("/daily-total", methods=["GET"])
@token_required
def get_daily_total():
    on_date = request.args.get("date", date_cls.today().isoformat())

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE timestamp::date = %s",
                (on_date,),
            )
            total = cur.fetchone()["total"]
    finally:
        conn.close()

    return jsonify({"total": float(total)})


@cashier_bp.route("/payments/<payment_id>/refund", methods=["POST"])
@token_required
def refund_payment(payment_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE payments SET status = 'refunded' WHERE id = %s RETURNING id",
                (payment_id,),
            )
            updated = cur.fetchone()
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    if updated is None:
        return jsonify({"error": "Payment not found."}), 404
    return jsonify({"ok": True})
