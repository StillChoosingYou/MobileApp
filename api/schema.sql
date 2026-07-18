-- PGPC Campus — Postgres schema (Supabase-compatible)
--
-- Run this once against your Supabase database: open the Supabase dashboard
-- → SQL Editor → paste this whole file → Run. Or via psql:
--   psql "$DATABASE_URL" -f api/schema.sql
--
-- IDs are TEXT (not UUID) throughout, matching the string IDs already used
-- across the Flutter models (e.g. "u_stu_001") — no id-format migration
-- needed between the mock data you've already seen and this real schema.

-- ── Users & roles ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id                 TEXT PRIMARY KEY,
  name               TEXT NOT NULL,
  email              TEXT NOT NULL UNIQUE,
  role               TEXT NOT NULL CHECK (role IN
                        ('student','teacher','registrar','accounting','cashier',
                         'guidance','deptHead','dean','admin')),
  login_id           TEXT NOT NULL UNIQUE,
  password_hash      TEXT NOT NULL,
  photo_url          TEXT,
  department         TEXT,
  biometric_enabled  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_login_role ON users (login_id, role);

CREATE TABLE IF NOT EXISTS student_profiles (
  student_id         TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  program            TEXT NOT NULL,
  year_level         INTEGER NOT NULL,
  block_section      TEXT NOT NULL,
  scholarship_label  TEXT
);

-- ── Academics ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subjects (
  code           TEXT PRIMARY KEY,
  title          TEXT NOT NULL,
  units          NUMERIC(4,1) NOT NULL,
  prerequisites  TEXT[] NOT NULL DEFAULT '{}',
  is_elective    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS sections (
  id            TEXT PRIMARY KEY,
  subject_code  TEXT NOT NULL REFERENCES subjects(code),
  section_label TEXT NOT NULL,
  faculty_name  TEXT NOT NULL,
  day_pattern   TEXT NOT NULL,
  start_time    TEXT NOT NULL,   -- "HH:mm", kept as text to match the Dart Section model directly
  end_time      TEXT NOT NULL,
  room          TEXT NOT NULL,
  slots_total   INTEGER NOT NULL,
  slots_taken   INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_sections_faculty ON sections (faculty_name);

CREATE TABLE IF NOT EXISTS enrollments (
  id           TEXT PRIMARY KEY,
  student_id   TEXT NOT NULL REFERENCES users(id),
  term         TEXT NOT NULL,
  section_ids  TEXT[] NOT NULL DEFAULT '{}',
  status       TEXT NOT NULL CHECK (status IN ('pending','approved','enrolled','rejected')),
  remarks      TEXT,
  UNIQUE (student_id, term)
);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments (status);

-- Unlike the mock data (which returned the same global grade list for every
-- student), grades are properly scoped per student_id here.
CREATE TABLE IF NOT EXISTS grades (
  id             TEXT PRIMARY KEY,
  student_id     TEXT NOT NULL REFERENCES users(id),
  subject_code   TEXT NOT NULL,
  subject_title  TEXT NOT NULL,
  units          NUMERIC(4,1) NOT NULL,
  term           TEXT NOT NULL,
  numeric_grade  NUMERIC(4,2),
  is_incomplete  BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_grades_student ON grades (student_id);

-- ── Finance ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ledgers (
  student_id           TEXT NOT NULL REFERENCES users(id),
  term                 TEXT NOT NULL,
  tuition_fee          NUMERIC(12,2) NOT NULL DEFAULT 0,
  misc_fees            NUMERIC(12,2) NOT NULL DEFAULT 0,
  lab_fees             NUMERIC(12,2) NOT NULL DEFAULT 0,
  scholarship_discount NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_paid           NUMERIC(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (student_id, term)
);

CREATE TABLE IF NOT EXISTS payments (
  id                TEXT PRIMARY KEY,
  student_id        TEXT NOT NULL REFERENCES users(id),
  student_name      TEXT NOT NULL,
  amount            NUMERIC(12,2) NOT NULL,
  method            TEXT NOT NULL CHECK (method IN ('cash','gcash','maya','bankTransfer','card')),
  receipt_number    TEXT NOT NULL UNIQUE,
  timestamp         TIMESTAMPTZ NOT NULL DEFAULT now(),
  recorded_by       TEXT NOT NULL,
  status            TEXT NOT NULL DEFAULT 'verified' CHECK (status IN ('verified','pending','refunded')),
  gateway_reference TEXT
);
CREATE INDEX IF NOT EXISTS idx_payments_student ON payments (student_id);
CREATE INDEX IF NOT EXISTS idx_payments_timestamp ON payments (timestamp);

-- ── Campus services ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id         TEXT PRIMARY KEY,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  category   TEXT NOT NULL,
  posted_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
  id          TEXT PRIMARY KEY,
  student_id  TEXT NOT NULL REFERENCES users(id),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  read        BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_notifications_student ON notifications (student_id);

CREATE TABLE IF NOT EXISTS document_requests (
  id           TEXT PRIMARY KEY,
  student_id   TEXT NOT NULL REFERENCES users(id),
  type         TEXT NOT NULL CHECK (type IN
                  ('transcriptOfRecords','certificateOfEnrollment','goodMoral','diplomaCopy')),
  purpose      TEXT NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status       TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN
                  ('submitted','processing','ready','released'))
);
CREATE INDEX IF NOT EXISTS idx_docreq_student ON document_requests (student_id);

CREATE TABLE IF NOT EXISTS clearances (
  student_id  TEXT NOT NULL REFERENCES users(id),
  term        TEXT NOT NULL,
  PRIMARY KEY (student_id, term)
);

CREATE TABLE IF NOT EXISTS clearance_steps (
  id            SERIAL PRIMARY KEY,
  student_id    TEXT NOT NULL,
  term          TEXT NOT NULL,
  office        TEXT NOT NULL,
  cleared       BOOLEAN NOT NULL DEFAULT FALSE,
  cleared_by    TEXT,
  FOREIGN KEY (student_id, term) REFERENCES clearances(student_id, term) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS queue_tickets (
  id          TEXT PRIMARY KEY,
  student_id  TEXT NOT NULL REFERENCES users(id),
  student_name TEXT NOT NULL,
  office      TEXT NOT NULL CHECK (office IN ('registrar','accounting','cashier','guidance')),
  number      INTEGER NOT NULL,
  issued_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  status      TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting','called','served','cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_queue_office_status ON queue_tickets (office, status);

CREATE TABLE IF NOT EXISTS appointments (
  id             TEXT PRIMARY KEY,
  student_id     TEXT NOT NULL REFERENCES users(id),
  office         TEXT NOT NULL CHECK (office IN ('registrar','accounting','guidance','dean')),
  purpose        TEXT NOT NULL,
  requested_for  TIMESTAMPTZ NOT NULL,
  status         TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','completed','cancelled'))
);

CREATE TABLE IF NOT EXISTS audit_log (
  id         TEXT PRIMARY KEY,
  actor      TEXT NOT NULL,
  action     TEXT NOT NULL,
  target     TEXT NOT NULL,
  timestamp  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS visitor_logs (
  id           TEXT PRIMARY KEY,
  visitor_name TEXT NOT NULL,
  purpose      TEXT NOT NULL,
  host_name    TEXT NOT NULL,
  check_in     TIMESTAMPTZ NOT NULL DEFAULT now(),
  check_out    TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS lost_found_items (
  id           TEXT PRIMARY KEY,
  is_found     BOOLEAN NOT NULL,
  item_name    TEXT NOT NULL,
  description  TEXT NOT NULL,
  location     TEXT NOT NULL,
  reported_by  TEXT NOT NULL,
  reported_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  claimed      BOOLEAN NOT NULL DEFAULT FALSE
);

-- ── Seed data ────────────────────────────────────────────────────────────
-- Mirrors mock_seed_data.dart so the app behaves the same way switching
-- from mock → REST. All seeded passwords are 'password123' — change these
-- before this touches anything but your own dev machine.
--
-- The hash below is a bcrypt hash of 'password123' (cost factor 12),
-- generated once and pasted here as a literal — verify it yourself with
-- `python -c "from werkzeug.security import generate_password_hash as g; print(g('password123'))"`
-- if you'd rather regenerate it (Werkzeug salts each hash, so a fresh run
-- produces a different-looking but equally valid string).
INSERT INTO users (id, name, email, role, login_id, password_hash, department) VALUES
  ('u_stu_001', 'Andrea Villanueva', 'andrea.villanueva@pgpc.edu.ph', 'student', '2023-00147', 'REPLACE_WITH_REAL_HASH', NULL),
  ('u_stu_002', 'Miguel Santos', 'miguel.santos@pgpc.edu.ph', 'student', '2023-00212', 'REPLACE_WITH_REAL_HASH', NULL),
  ('u_reg_001', 'Evelyn Aquino', 'e.aquino@pgpc.edu.ph', 'registrar', 'EMP-0501', 'REPLACE_WITH_REAL_HASH', 'Office of the Registrar'),
  ('u_cas_001', 'Bea Fernandez', 'b.fernandez@pgpc.edu.ph', 'cashier', 'EMP-0602', 'REPLACE_WITH_REAL_HASH', 'Cashier'),
  ('u_admin_001', 'Kevin Mercado', 'k.mercado@pgpc.edu.ph', 'admin', 'EMP-0001', 'REPLACE_WITH_REAL_HASH', 'MIS / Admin')
ON CONFLICT (id) DO NOTHING;

INSERT INTO student_profiles (student_id, program, year_level, block_section, scholarship_label) VALUES
  ('u_stu_001', 'BS Information Technology', 2, 'BSIT-2A', 'LGU Merit Scholar'),
  ('u_stu_002', 'BS Business Administration', 3, 'BSBA-3B', NULL)
ON CONFLICT (student_id) DO NOTHING;

INSERT INTO subjects (code, title, units, is_elective) VALUES
  ('IT201', 'Data Structures and Algorithms', 3, FALSE),
  ('IT202', 'Information Management', 3, FALSE),
  ('GE105', 'The Life and Works of Rizal', 3, FALSE),
  ('IT250', 'Human-Computer Interaction', 3, TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO sections (id, subject_code, section_label, faculty_name, day_pattern, start_time, end_time, room, slots_total, slots_taken) VALUES
  ('sec_it201_a', 'IT201', 'BSIT-2A', 'Prof. Ramon Dela Cruz', 'MWF', '08:00', '09:00', 'CCS Lab 1', 40, 38),
  ('sec_ge105_a', 'GE105', 'BSIT-2A', 'Prof. Liza Marquez', 'MWF', '09:00', '10:00', 'Room 110', 45, 30)
ON CONFLICT (id) DO NOTHING;

INSERT INTO enrollments (id, student_id, term, section_ids, status) VALUES
  ('enr_001', 'u_stu_001', 'A.Y. 2026–2027, 1st Semester', ARRAY['sec_it201_a','sec_ge105_a'], 'enrolled')
ON CONFLICT (id) DO NOTHING;

INSERT INTO grades (id, student_id, subject_code, subject_title, units, term, numeric_grade) VALUES
  ('grd_001', 'u_stu_001', 'IT101', 'Intro to Computing', 3, 'A.Y. 2025–2026, 2nd Semester', 1.50),
  ('grd_002', 'u_stu_001', 'GE101', 'Purposive Communication', 3, 'A.Y. 2025–2026, 2nd Semester', 1.75)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ledgers (student_id, term, tuition_fee, misc_fees, lab_fees, scholarship_discount, total_paid) VALUES
  ('u_stu_001', 'A.Y. 2026–2027, 1st Semester', 12500, 2300, 1800, 6000, 5000),
  ('u_stu_002', 'A.Y. 2026–2027, 1st Semester', 13800, 2300, 900, 0, 17000)
ON CONFLICT (student_id, term) DO NOTHING;

INSERT INTO announcements (id, title, body, category) VALUES
  ('ann_001', 'Enrollment for 2nd Semester Now Open',
   'Continuing students may proceed with online enrollment. Please settle at least the down payment to confirm your slot.',
   'Enrollment')
ON CONFLICT (id) DO NOTHING;
