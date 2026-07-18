from flask import Blueprint, jsonify, request

from auth_utils import create_token, token_required, verify_password
from db import get_connection

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    role = data.get("role")
    login_id = data.get("loginId")
    password = data.get("password")

    if not role or not login_id or not password:
        return jsonify({"error": "role, loginId, and password are all required."}), 400

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM users WHERE login_id = %s AND role = %s AND is_active = TRUE",
                (login_id, role),
            )
            user = cur.fetchone()
    finally:
        conn.close()

    if user is None:
        return jsonify({"error": f"No {role} account found for that ID."}), 404

    if not verify_password(password, user["password_hash"]):
        return jsonify({"error": "Incorrect password."}), 401

    token = create_token(user["id"], user["role"])
    return jsonify(
        {
            "token": token,
            "user": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"],
                "role": user["role"],
                "loginId": user["login_id"],
                "photoUrl": user["photo_url"],
                "department": user["department"],
                "biometricEnabled": user["biometric_enabled"],
            },
        }
    )


@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    data = request.get_json(silent=True) or {}
    identifier = data.get("emailOrLoginId", "")

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM users WHERE email = %s OR login_id = %s",
                (identifier, identifier),
            )
            user = cur.fetchone()
    finally:
        conn.close()

    if user is None:
        return jsonify({"error": "We could not find an account with that email or ID."}), 404

    # No real email is sent here — this only confirms the account exists.
    # Wire up an actual email provider (Resend, Postmark, SES, ...) before
    # this touches real users.
    return jsonify({"ok": True})


@auth_bp.route("/enable-biometric", methods=["POST"])
@token_required
def enable_biometric():
    user_id = request.auth_user["sub"]

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET biometric_enabled = TRUE WHERE id = %s", (user_id,))
        conn.commit()
    finally:
        conn.close()

    return jsonify({"ok": True})
