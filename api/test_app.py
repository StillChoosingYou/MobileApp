"""
Tests for the PGPC Campus Flask API. These mock `get_connection()` so they
run without a live Postgres connection — good for quick local iteration and
CI. They exercise the same request/response cycle Flutter's
ApiAuthRepository / ApiStudentRepository / ApiCashierRepository depend on,
so a route rename or response-shape change here should be caught before it
silently breaks the app.

Run with:
    pip install -r requirements.txt -r requirements-dev.txt
    pytest api/test_app.py -v
"""

import os
import sys
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(__file__))

os.environ.setdefault("JWT_SECRET", "test-secret-only-used-while-running-pytest-32b")

import main  # noqa: E402  (must come after sys.path insert / env setdefault above)
from auth_utils import create_token, decode_token, hash_password  # noqa: E402


@pytest.fixture
def client():
    return main.app.test_client()


def _mock_cursor(fetchone_return=None, fetchall_return=None):
    """A cursor usable as `with conn.cursor() as cur:` that returns canned
    data for `.fetchone()` / `.fetchall()` regardless of the query run."""
    cur = MagicMock()
    cur.__enter__.return_value = cur
    cur.fetchone.return_value = fetchone_return
    cur.fetchall.return_value = fetchall_return or []
    return cur


def _mock_conn(cursor):
    conn = MagicMock()
    conn.cursor.return_value = cursor
    return conn


def test_health_check(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "ok"}


def test_jwt_round_trip():
    token = create_token("u_stu_001", "student")
    decoded = decode_token(token)
    assert decoded["sub"] == "u_stu_001"
    assert decoded["role"] == "student"


def test_login_success(client):
    fake_user = {
        "id": "u_stu_001",
        "name": "Andrea Villanueva",
        "email": "andrea@pgpc.edu.ph",
        "role": "student",
        "login_id": "2023-00147",
        "password_hash": hash_password("password123"),
        "photo_url": None,
        "department": None,
        "biometric_enabled": False,
    }
    conn = _mock_conn(_mock_cursor(fetchone_return=fake_user))

    with patch("routes.auth.get_connection", return_value=conn):
        res = client.post(
            "/api/auth/login",
            json={"role": "student", "loginId": "2023-00147", "password": "password123"},
        )

    assert res.status_code == 200
    body = res.get_json()
    assert "token" in body
    assert body["user"]["id"] == "u_stu_001"
    # The password hash must never round-trip back to the client.
    assert "password_hash" not in body["user"]
    assert "passwordHash" not in body["user"]


def test_login_wrong_password(client):
    fake_user = {
        "id": "u_stu_001",
        "name": "Andrea Villanueva",
        "email": "andrea@pgpc.edu.ph",
        "role": "student",
        "login_id": "2023-00147",
        "password_hash": hash_password("password123"),
        "photo_url": None,
        "department": None,
        "biometric_enabled": False,
    }
    conn = _mock_conn(_mock_cursor(fetchone_return=fake_user))

    with patch("routes.auth.get_connection", return_value=conn):
        res = client.post(
            "/api/auth/login",
            json={"role": "student", "loginId": "2023-00147", "password": "wrong"},
        )

    assert res.status_code == 401


def test_login_account_not_found(client):
    conn = _mock_conn(_mock_cursor(fetchone_return=None))

    with patch("routes.auth.get_connection", return_value=conn):
        res = client.post(
            "/api/auth/login",
            json={"role": "student", "loginId": "no-such-id", "password": "x"},
        )

    assert res.status_code == 404


def test_protected_route_requires_auth_header(client):
    res = client.get("/api/student/u_stu_001/profile")
    assert res.status_code == 401


def test_protected_route_rejects_garbage_token(client):
    res = client.get(
        "/api/student/u_stu_001/profile",
        headers={"Authorization": "Bearer not-a-real-token"},
    )
    assert res.status_code == 401


def test_protected_route_with_valid_token(client):
    token = create_token("u_stu_001", "student")
    fake_profile = {
        "student_id": "u_stu_001",
        "program": "BS Information Technology",
        "year_level": 2,
        "block_section": "BSIT-2A",
        "scholarship_label": None,
    }
    conn = _mock_conn(_mock_cursor(fetchone_return=fake_profile))

    with patch("routes.student.get_connection", return_value=conn):
        res = client.get(
            "/api/student/u_stu_001/profile",
            headers={"Authorization": f"Bearer {token}"},
        )

    assert res.status_code == 200
    assert res.get_json()["program"] == "BS Information Technology"


def test_cashier_record_payment_updates_ledger_and_logs(client):
    token = create_token("u_cas_001", "cashier")
    cur = _mock_cursor(fetchone_return={"n": 5})
    conn = _mock_conn(cur)

    with patch("routes.cashier.get_connection", return_value=conn):
        res = client.post(
            "/api/cashier/payments",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "studentId": "u_stu_001",
                "studentName": "Andrea Villanueva",
                "amount": 1500,
                "method": "gcash",
                "recordedBy": "Bea Fernandez",
            },
        )

    assert res.status_code == 200
    body = res.get_json()
    assert body["receiptNumber"].startswith("OR-")
    assert body["status"] == "verified"

    # The route should INSERT the payment, UPDATE the ledger, and INSERT an
    # audit log entry, then commit — all inside one connection.
    executed_queries = [call.args[0] for call in cur.execute.call_args_list]
    assert any("INSERT INTO payments" in q for q in executed_queries)
    assert any("UPDATE ledgers" in q for q in executed_queries)
    assert any("INSERT INTO audit_log" in q for q in executed_queries)
    assert conn.commit.called


def test_cashier_record_payment_rejects_non_positive_amount(client):
    token = create_token("u_cas_001", "cashier")
    res = client.post(
        "/api/cashier/payments",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "studentId": "u_stu_001",
            "studentName": "Andrea Villanueva",
            "amount": 0,
            "method": "cash",
            "recordedBy": "Bea Fernandez",
        },
    )
    assert res.status_code == 400
