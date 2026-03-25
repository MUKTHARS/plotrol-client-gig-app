-- Plotrol New Database Schema (PostgreSQL)
-- The Go backend auto-creates these on startup; run manually only if needed.

CREATE DATABASE plotrol_new;

\c plotrol_new;

CREATE TABLE IF NOT EXISTS users (
    id            SERIAL       PRIMARY KEY,
    uuid          VARCHAR(36)  NOT NULL UNIQUE,
    user_name     VARCHAR(200) NOT NULL UNIQUE,
    name          VARCHAR(200),
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    mobile_number VARCHAR(30)  UNIQUE,
    email_id      VARCHAR(200) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    type          VARCHAR(50)  NOT NULL DEFAULT 'EMPLOYEE',
    tenant_id     VARCHAR(50)  NOT NULL DEFAULT 'mz',
    role_code     VARCHAR(50)  NOT NULL DEFAULT 'DISTRIBUTOR',
    role_name     VARCHAR(100) NOT NULL DEFAULT 'Distributor',
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    address       TEXT,
    suburb        VARCHAR(100),
    city          VARCHAR(100),
    state_name    VARCHAR(100),
    postcode      VARCHAR(20),
    latitude      VARCHAR(50),
    longitude     VARCHAR(50),
    tenant_image  TEXT,
    device_type   VARCHAR(50),
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number);
CREATE INDEX IF NOT EXISTS idx_users_email  ON users(email_id);

-- Role codes used by Flutter routing:
--   DISTRIBUTOR   → regular user  → HomeView
--   PGR_ADMIN     → admin         → GigHomeView
--   HELPDESK_USER → gig worker    → GigHomeView
