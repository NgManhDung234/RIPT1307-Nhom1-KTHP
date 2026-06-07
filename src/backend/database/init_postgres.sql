-- PostgreSQL Init Script for Student Management System
-- Run this script to create database and tables

-- Create database (run this separately if needed)
-- CREATE DATABASE student_management;
-- \c student_management;

-- =========================================================================
-- 1. DROP TABLES IN CORRECT ORDER (to avoid foreign key constraints)
-- =========================================================================
DROP TABLE IF EXISTS email_logs CASCADE;
DROP TABLE IF EXISTS admission_wishes CASCADE;
DROP TABLE IF EXISTS admission_applications CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS potential_students CASCADE;
DROP TABLE IF EXISTS admin_online_status CASCADE;
DROP TABLE IF EXISTS chat_history CASCADE;
DROP TABLE IF EXISTS major_combinations CASCADE;
DROP TABLE IF EXISTS combinations CASCADE;
DROP TABLE IF EXISTS majors CASCADE;
DROP TABLE IF EXISTS universities CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- =========================================================================
-- 2. CREATE ENUM TYPES
-- =========================================================================
CREATE TYPE gender_enum AS ENUM ('MALE', 'FEMALE', 'OTHER');
CREATE TYPE priority_area_enum AS ENUM ('KV1', 'KV2-NT', 'KV2', 'KV3');
CREATE TYPE priority_object_enum AS ENUM ('UT1', 'UT2');
CREATE TYPE profile_status_enum AS ENUM ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE application_status_enum AS ENUM ('draft', 'submitted', 'reviewing', 'approved', 'rejected', 'needs_revision');
CREATE TYPE email_type_enum AS ENUM ('SUBMIT_SUCCESS', 'STATUS_CHANGED');
CREATE TYPE chat_role_enum AS ENUM ('user', 'assistant', 'admin', 'system');

-- =========================================================================
-- 3. CREATE SYSTEM & USER TABLES
-- =========================================================================
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL,
    student_code VARCHAR(50) UNIQUE,
    phone VARCHAR(20),
    avatar VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_roles FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_reset_tokens_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_username_email ON users(username, email);

-- =========================================================================
-- 4. CREATE CATALOG TABLES (Universities, Majors, Combinations)
-- =========================================================================
CREATE TABLE universities (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE majors (
    id SERIAL PRIMARY KEY,
    university_id INTEGER NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    UNIQUE (university_id, code),
    CONSTRAINT fk_majors_universities FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE CASCADE
);

CREATE TABLE combinations (
    id SERIAL PRIMARY KEY,
    code VARCHAR(5) NOT NULL UNIQUE,
    subject_names VARCHAR(255) NOT NULL
);

CREATE TABLE major_combinations (
    major_id INTEGER NOT NULL,
    combination_id INTEGER NOT NULL,
    PRIMARY KEY (major_id, combination_id),
    CONSTRAINT fk_major_combinations_majors FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE,
    CONSTRAINT fk_major_combinations_combinations FOREIGN KEY (combination_id) REFERENCES combinations(id) ON DELETE CASCADE
);

-- =========================================================================
-- 5. CREATE ADMISSION & APPLICATION TABLES
-- =========================================================================
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    full_name VARCHAR(100),
    dob DATE,
    gender gender_enum,
    ethnicity VARCHAR(50),
    religion VARCHAR(50),
    pob VARCHAR(100),
    phone VARCHAR(20) UNIQUE,
    cccd_number VARCHAR(20) UNIQUE,
    permanent_address TEXT,
    high_school_info JSONB,
    priority_area priority_area_enum,
    priority_object priority_object_enum,
    cccd_front_url VARCHAR(255),
    cccd_back_url VARCHAR(255),
    avatar_url VARCHAR(255),
    score_subject_1 DECIMAL(4,2),
    score_subject_2 DECIMAL(4,2),
    score_subject_3 DECIMAL(4,2),
    total_score DECIMAL(5,2),
    priority_score DECIMAL(4,2),
    final_score DECIMAL(5,2),
    status profile_status_enum DEFAULT 'DRAFT',
    reject_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_profiles_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    profile_id INTEGER NOT NULL,
    university_id INTEGER NOT NULL,
    major_id INTEGER NOT NULL,
    combination_id INTEGER NOT NULL,
    priority_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (profile_id, priority_order),
    UNIQUE (profile_id, university_id, major_id),
    CONSTRAINT fk_applications_profiles FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_applications_universities FOREIGN KEY (university_id) REFERENCES universities(id),
    CONSTRAINT fk_applications_majors FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_applications_combinations FOREIGN KEY (combination_id) REFERENCES combinations(id)
);

CREATE TABLE email_logs (
    id SERIAL PRIMARY KEY,
    profile_id INTEGER NOT NULL,
    email_type email_type_enum NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_email_logs_profiles FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- =========================================================================
-- 6. ADMISSION APPLICATIONS TABLES
-- =========================================================================
CREATE TABLE admission_applications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    status application_status_enum DEFAULT 'draft',
    personal_info JSONB,
    academic_info JSONB,
    documents_info JSONB,
    confirmation_checked BOOLEAN DEFAULT FALSE,
    submitted_at TIMESTAMP,
    reviewed_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_admission_applications_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE admission_wishes (
    id SERIAL PRIMARY KEY,
    application_id INTEGER NOT NULL,
    priority_order INTEGER NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    major_name VARCHAR(255) NOT NULL,
    subject_group VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_admission_wishes_applications FOREIGN KEY (application_id) REFERENCES admission_applications(id) ON DELETE CASCADE
);

-- =========================================================================
-- 7. POTENTIAL STUDENTS TABLE (AI extracted from chat)
-- =========================================================================
CREATE TABLE potential_students (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(100),
    user_id INTEGER,
    student_name VARCHAR(255),
    score DECIMAL(5,2),
    subject_group VARCHAR(50),
    target_major VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    notes TEXT,
    reviewed BOOLEAN DEFAULT FALSE,
    reviewed_by INTEGER,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_potential_students_reviewed ON potential_students(reviewed);
CREATE INDEX idx_potential_students_created ON potential_students(created_at);
CREATE INDEX idx_potential_students_session ON potential_students(session_id);

-- =========================================================================
-- 8. CHAT HISTORY & ONLINE STATUS TABLES
-- =========================================================================
CREATE TABLE chat_history (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    user_id INTEGER,
    role chat_role_enum NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_history_session ON chat_history(session_id);
CREATE INDEX idx_chat_history_user ON chat_history(user_id);
CREATE INDEX idx_chat_history_created ON chat_history(created_at);

CREATE TABLE admin_online_status (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL UNIQUE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_admin_online_status_users FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =========================================================================
-- 9. CUTOFF SCORES TABLE
-- =========================================================================
CREATE TABLE cutoff_scores (
    id SERIAL PRIMARY KEY,
    university_id INTEGER NOT NULL,
    combination_id INTEGER NOT NULL,
    year INTEGER NOT NULL DEFAULT 2026,
    score DECIMAL(4,2) NOT NULL,
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (university_id, combination_id, year),
    CONSTRAINT fk_cutoff_scores_universities FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE CASCADE,
    CONSTRAINT fk_cutoff_scores_combinations FOREIGN KEY (combination_id) REFERENCES combinations(id) ON DELETE CASCADE
);

CREATE INDEX idx_cutoff_scores_year ON cutoff_scores(year);

-- =========================================================================
-- 10. INSERT SAMPLE DATA
-- =========================================================================

-- Roles
INSERT INTO roles (name, description) VALUES
    ('manager', 'Tài khoản quản lý'),
    ('student', 'Tài khoản sinh viên');

-- Users (passwords: manager123, student123)
INSERT INTO users (full_name, email, username, password_hash, role_id, student_code, phone) VALUES
    ('Nguyễn Văn Quản Lý', 'manager@example.com', 'manager01', '$2b$10$8IaJ8Wec9f/XLHfdLMMvu.BWbF18KTx110RxxBKzir1kK0OF5up5W', 1, NULL, '0987654321'),
    ('Nguyễn Văn Sinh Viên', 'student@example.com', 'student01', '$2b$10$7rYi61beqlsXPQFXx4DMmOD8pjKdvRBwsCT.JGCiVi7fEC4X1QPFu', 2, 'SV001', '0123456789');

-- Universities
INSERT INTO universities (code, name) VALUES
    ('BKH','Trường Đại học Bách Khoa Hà Nội'),
    ('NEU','Trường Đại học Kinh tế Quốc dân'),
    ('VNU','Trường Đại học Quốc gia Hà Nội'),
    ('FTU','Trường Đại học Ngoại thương'),
    ('PTIT','Học viện Công nghệ Bưu chính Viễn thông');

-- Combinations
INSERT INTO combinations (code, subject_names) VALUES
    ('A00','Toán, Vật lý, Hóa học'),
    ('A01','Toán, Vật lý, Tiếng Anh'),
    ('D01','Toán, Văn, Tiếng Anh'),
    ('C00','Văn, Sử, Địa'),
    ('B00','Toán, Hóa, Sinh');

-- Majors
INSERT INTO majors (university_id, code, name) VALUES
    (1,'CNTT','Công nghệ thông tin'),
    (1,'DTVT','Điện tử viễn thông'),
    (1,'KTCK','Kỹ thuật cơ khí'),
    (2,'QTKD','Quản trị kinh doanh'),
    (2,'KT','Kế toán'),
    (3,'LUAT','Luật'),
    (4,'KTE','Kinh tế đối ngoại'),
    (5,'CNTT','Công nghệ thông tin'),
    (5,'ATTT','An toàn thông tin');

-- Major-Combinations
INSERT INTO major_combinations (major_id, combination_id) VALUES
    (1,1),(1,2),(2,1),(2,2),(3,1),(4,3),(4,1),(5,1),(5,3),(6,3),(7,3),(7,1),(8,1),(8,2),(9,1),(9,2);

-- Sample Profile
INSERT INTO profiles (user_id, full_name, dob, gender, cccd_number, phone, permanent_address, priority_area, priority_object, score_subject_1, score_subject_2, score_subject_3, total_score, priority_score, final_score, status, cccd_front_url, cccd_back_url, avatar_url)
SELECT u.id, 'Nguyễn Văn Sinh Viên', '2006-05-15', 'MALE', '001234567890', '0123456789',
'123 Đường Lê Lợi, Quận 1, TP.HCM', 'KV1', 'UT2',
8.5, 7.0, 9.0, 24.5, 0.5, 25.0, 'PENDING',
'/uploads/cccd_front.jpg', '/uploads/cccd_back.jpg', '/uploads/avatar.jpg'
FROM users u WHERE u.username='student01';

-- Cutoff Scores 2026
INSERT INTO cutoff_scores (university_id, combination_id, year, score, notes)
SELECT u.id, c.id, 2026, cs.score, cs.notes FROM
(SELECT 'BKH' AS university_code, 'A00' AS combination_code, 27.75 AS score, 'Khối A00 - Toán, Lý, Hóa' AS notes UNION ALL
 SELECT 'BKH', 'A01', 28.00, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'BKH', 'D01', 29.00, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'BKH', 'C00', 27.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'D01', 26.50, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'NEU', 'C00', 26.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'A00', 27.00, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A00', 28.25, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A01', 27.75, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'VNU', 'D01', 28.00, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'VNU', 'C00', 27.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'D01', 27.50, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'FTU', 'C00', 27.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'A00', 28.00, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A00', 27.75, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A01', 27.50, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'PTIT', 'D01', 28.00, 'Khối D01 - Toán, Văn, Anh') AS cs
JOIN universities u ON u.code = cs.university_code
JOIN combinations c ON c.code = cs.combination_code;

-- Cutoff Scores 2025
INSERT INTO cutoff_scores (university_id, combination_id, year, score, notes)
SELECT u.id, c.id, 2025, cs.score, cs.notes FROM
(SELECT 'BKH' AS university_code, 'A00' AS combination_code, 27.50 AS score, 'Khối A00 - Toán, Lý, Hóa' AS notes UNION ALL
 SELECT 'BKH', 'A01', 27.75, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'BKH', 'D01', 28.50, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'BKH', 'C00', 26.75, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'D01', 26.25, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'NEU', 'C00', 25.75, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'A00', 26.50, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A00', 27.75, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A01', 27.50, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'VNU', 'D01', 27.50, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'VNU', 'C00', 26.50, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'D01', 27.00, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'FTU', 'C00', 26.50, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'A00', 27.25, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A00', 27.25, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A01', 27.00, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'PTIT', 'D01', 27.50, 'Khối D01 - Toán, Văn, Anh') AS cs
JOIN universities u ON u.code = cs.university_code
JOIN combinations c ON c.code = cs.combination_code;

-- Cutoff Scores 2024
INSERT INTO cutoff_scores (university_id, combination_id, year, score, notes)
SELECT u.id, c.id, 2024, cs.score, cs.notes FROM
(SELECT 'BKH' AS university_code, 'A00' AS combination_code, 27.00 AS score, 'Khối A00 - Toán, Lý, Hóa' AS notes UNION ALL
 SELECT 'BKH', 'A01', 27.25, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'BKH', 'D01', 28.00, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'BKH', 'C00', 26.25, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'D01', 25.75, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'NEU', 'C00', 25.25, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'NEU', 'A00', 26.00, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A00', 27.25, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'VNU', 'A01', 27.00, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'VNU', 'D01', 27.00, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'VNU', 'C00', 26.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'D01', 26.50, 'Khối D01 - Toán, Văn, Anh' UNION ALL
 SELECT 'FTU', 'C00', 26.00, 'Khối C00 - Văn, Sử, Địa' UNION ALL
 SELECT 'FTU', 'A00', 26.75, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A00', 26.75, 'Khối A00 - Toán, Lý, Hóa' UNION ALL
 SELECT 'PTIT', 'A01', 26.50, 'Khối A01 - Toán, Lý, Anh' UNION ALL
 SELECT 'PTIT', 'D01', 27.00, 'Khối D01 - Toán, Văn, Anh') AS cs
JOIN universities u ON u.code = cs.university_code
JOIN combinations c ON c.code = cs.combination_code;

-- =========================================================================
-- 11. VERIFY DATA
-- =========================================================================
SELECT users.id, users.full_name, users.email, users.username, roles.name AS role, users.is_active
FROM users JOIN roles ON users.role_id = roles.id;
