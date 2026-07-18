import datetime
import os
from functools import wraps

import jwt
from flask import jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

JWT_SECRET = os.environ.get("JWT_SECRET", "dev-only-insecure-fallback-secret-do-not-use-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_HOURS = 24 * 7  # a week — adjust to taste


def hash_password(plain: str) -> str:
    return generate_password_hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return check_password_hash(hashed, plain)


def create_token(user_id: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "role": role,
        "exp": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=JWT_EXPIRY_HOURS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


def token_required(f):
    """
    Route decorator: requires a valid `Authorization: Bearer <token>`
    header. On success, the decoded claims are available as
    `request.auth_user` (a dict with at least 'sub' — the user id — and
    'role').

    This only checks the token is VALID. It does not check the token's
    role is allowed to call this specific route — see the note at the top
    of routes/cashier.py for where and how to add that check before this
    handles real students' money.
    """

    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header."}), 401

        token = auth_header[7:].strip()
        try:
            request.auth_user = decode_token(token)
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Session expired. Please log in again."}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid session token."}), 401

        return f(*args, **kwargs)

    return wrapper
