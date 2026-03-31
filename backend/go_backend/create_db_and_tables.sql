-- backend/go_backend/create_db_and_tables.sql
-- Creates database and all backend tables for Plotrol.
-- Run with: psql -U postgres -f create_db_and_tables.sql

CREATE DATABASE IF NOT EXISTS plotrol_new;
\c plotrol_new;

-- users
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
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email_id);

-- individuals
CREATE TABLE IF NOT EXISTS individuals (
    id                   SERIAL PRIMARY KEY,
    client_reference_id  VARCHAR(255) NOT NULL UNIQUE,
    tenant_id            VARCHAR(255),
    given_name           VARCHAR(255),
    family_name          VARCHAR(255),
    mobile_number        VARCHAR(255),
    email                VARCHAR(255),
    user_uuid            VARCHAR(255),
    is_deleted           BOOLEAN NOT NULL DEFAULT FALSE,
    is_system_user       BOOLEAN NOT NULL DEFAULT FALSE,
    non_recoverable_error BOOLEAN NOT NULL DEFAULT FALSE,
    row_version          INTEGER NOT NULL DEFAULT 1,
    created_by           VARCHAR(255),
    created_time         BIGINT,
    last_modified_by     VARCHAR(255),
    last_modified_time   BIGINT,
    created_at           TIMESTAMP,
    updated_at           TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_individuals_client_ref ON individuals(client_reference_id);

-- individual_addresses
CREATE TABLE IF NOT EXISTS individual_addresses (
    id            SERIAL PRIMARY KEY,
    individual_id INTEGER NOT NULL,
    tenant_id     VARCHAR(255),
    type          VARCHAR(255),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    landmark      VARCHAR(255),
    city          VARCHAR(255),
    pincode       VARCHAR(255),
    building_name VARCHAR(255),
    street        VARCHAR(255),
    locality_code VARCHAR(255),
    locality_name VARCHAR(255),
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    created_by    VARCHAR(255),
    created_time  BIGINT
);
CREATE INDEX IF NOT EXISTS idx_ind_addr_individual_id ON individual_addresses(individual_id);

-- individual_identifiers
CREATE TABLE IF NOT EXISTS individual_identifiers (
    id                 SERIAL PRIMARY KEY,
    individual_id      INTEGER NOT NULL,
    client_reference_id VARCHAR(255),
    identifier_type    VARCHAR(255),
    identifier_id      VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_ind_ident_individual_id ON individual_identifiers(individual_id);

-- households
CREATE TABLE IF NOT EXISTS households (
    id                  SERIAL PRIMARY KEY,
    client_reference_id VARCHAR(255) NOT NULL UNIQUE,
    tenant_id           VARCHAR(255),
    household_type      VARCHAR(255),
    member_count        INTEGER NOT NULL DEFAULT 1,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    non_recoverable_error BOOLEAN NOT NULL DEFAULT FALSE,
    row_version         INTEGER NOT NULL DEFAULT 1,
    addr_tenant_id      VARCHAR(255),
    addr_type           VARCHAR(255),
    addr_address_line1  VARCHAR(255),
    addr_address_line2  VARCHAR(255),
    addr_landmark       VARCHAR(255),
    addr_city           VARCHAR(255),
    addr_pincode        VARCHAR(255),
    addr_building_name  VARCHAR(255),
    addr_street         VARCHAR(255),
    addr_locality_code  VARCHAR(255),
    addr_locality_name  VARCHAR(255),
    addr_latitude       DOUBLE PRECISION,
    addr_longitude      DOUBLE PRECISION,
    created_by          VARCHAR(255),
    created_time        BIGINT,
    last_modified_by    VARCHAR(255),
    last_modified_time  BIGINT,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_households_client_ref ON households(client_reference_id);

-- household_additional_fields
CREATE TABLE IF NOT EXISTS household_additional_fields (
    id          SERIAL PRIMARY KEY,
    household_id INTEGER NOT NULL,
    key         VARCHAR(255),
    value       TEXT
);
CREATE INDEX IF NOT EXISTS idx_household_additional_household_id ON household_additional_fields(household_id);

-- household_members
CREATE TABLE IF NOT EXISTS household_members (
    id                           SERIAL PRIMARY KEY,
    client_reference_id          VARCHAR(255) NOT NULL UNIQUE,
    household_id                 INTEGER,
    household_client_reference_id VARCHAR(255),
    individual_id                INTEGER,
    individual_client_reference_id VARCHAR(255),
    is_head_of_household         BOOLEAN NOT NULL DEFAULT FALSE,
    tenant_id                    VARCHAR(255),
    is_deleted                   BOOLEAN NOT NULL DEFAULT FALSE,
    non_recoverable_error        BOOLEAN NOT NULL DEFAULT FALSE,
    row_version                  INTEGER NOT NULL DEFAULT 1,
    created_by                   VARCHAR(255),
    created_time                 BIGINT,
    last_modified_by             VARCHAR(255),
    last_modified_time           BIGINT,
    created_at                   TIMESTAMP,
    updated_at                   TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_household_members_household_id ON household_members(household_id);
CREATE INDEX IF NOT EXISTS idx_household_members_individual_id ON household_members(individual_id);

-- file_stores
CREATE TABLE IF NOT EXISTS file_stores (
    id            SERIAL PRIMARY KEY,
    file_store_id VARCHAR(255) NOT NULL UNIQUE,
    name          VARCHAR(255),
    tenant_id     VARCHAR(255),
    module        VARCHAR(255),
    file_path     VARCHAR(255),
    url           TEXT,
    file_data     BYTEA,
    created_at    TIMESTAMP
);

-- pgr_service_requests
CREATE TABLE IF NOT EXISTS service_requests (
    id                     SERIAL PRIMARY KEY,
    service_request_id     VARCHAR(255) NOT NULL UNIQUE,
    tenant_id              VARCHAR(255),
    service_code           VARCHAR(255),
    description            TEXT,
    application_status     VARCHAR(255) NOT NULL DEFAULT 'PENDING_ASSIGNMENT',
    source                 VARCHAR(255),
    active                 BOOLEAN NOT NULL DEFAULT TRUE,
    row_version            INTEGER NOT NULL DEFAULT 1,
    additional_detail      TEXT,
    address_json           TEXT,
    user_json              TEXT,
    workflow_action        VARCHAR(255),
    workflow_assignes      TEXT,
    workflow_hrms_assignes TEXT,
    workflow_comments      TEXT,
    audit_created_by       VARCHAR(255),
    audit_created_time     BIGINT,
    audit_last_modified_by VARCHAR(255),
    audit_last_modified_time BIGINT,
    mobile_number          VARCHAR(255),
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP
);

-- Using the same `users` index names that existing code expects
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email_id);
