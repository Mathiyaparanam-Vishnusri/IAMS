-- ============================================================
-- Migration: 001_initial_schema.sql
-- Project:   Digitweb Lanka — Inventory & Asset Management System (IAMS)
-- Source:    Database_Blueprint_v2.md + Schema_Generation_Plan_v1.md
-- Date:      2026-06-24
-- Tables:    10
-- FKs:       17
-- Indexes:   31 (excluding auto-created PK indexes)
-- ============================================================

-- ============================================================
-- STEP 1: locations
-- Dependencies: none
-- ============================================================
CREATE TABLE locations (
    location_id  BIGSERIAL    PRIMARY KEY,
    location_name TEXT        NOT NULL,
    status        TEXT,
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 2: employees
-- Dependencies: locations
-- Deferred HR fields: status, joining_date, email (nullable)
-- ============================================================
CREATE TABLE employees (
    employee_id      BIGSERIAL   PRIMARY KEY,
    full_name        TEXT        NOT NULL,
    location_id      BIGINT      REFERENCES locations(location_id) ON DELETE SET NULL,
    designation      TEXT,
    department_team  TEXT,
    status           TEXT,                     -- DEFERRED: active / inactive / offboarded
    joining_date     DATE,                     -- DEFERRED: not yet available
    email            TEXT,                     -- DEFERRED: not yet available
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 3: asset_categories
-- Dependencies: self-referencing (parent_category added via ALTER TABLE below)
-- ============================================================
CREATE TABLE asset_categories (
    category_id    BIGSERIAL   PRIMARY KEY,
    category_name  TEXT        NOT NULL,
    parent_category BIGINT,                    -- FK added after table creation (self-ref)
    status         TEXT
);

-- Self-referencing FK added after table exists
ALTER TABLE asset_categories
    ADD CONSTRAINT fk_asset_categories_parent
    FOREIGN KEY (parent_category)
    REFERENCES asset_categories(category_id)
    ON DELETE SET NULL;

-- ============================================================
-- STEP 4: assets
-- Dependencies: locations, asset_categories
-- ============================================================
CREATE TABLE assets (
    asset_id        BIGSERIAL   PRIMARY KEY,
    asset_number    TEXT        NOT NULL UNIQUE,
    serial_number   TEXT,
    invoice_number  TEXT,
    item_name       TEXT        NOT NULL,
    category_id     BIGINT      REFERENCES asset_categories(category_id) ON DELETE SET NULL,
    brand           TEXT,
    model           TEXT,
    purchase_date   DATE,
    purchase_cost   NUMERIC,
    location_id     BIGINT      REFERENCES locations(location_id) ON DELETE SET NULL,
    current_status  TEXT        NOT NULL,      -- available / allocated / repair / disposed
    remarks         TEXT,
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 5: asset_allocations
-- Dependencies: assets, employees
-- ============================================================
CREATE TABLE asset_allocations (
    allocation_id             BIGSERIAL   PRIMARY KEY,
    asset_id                  BIGINT      NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    employee_id               BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    allocated_date            DATE        NOT NULL,
    allocated_by_employee_id  BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    allocation_condition      TEXT,
    expected_return_date      DATE,              -- NULLABLE: permanent allocations may have no return date
    remarks                   TEXT,
    returned_date             DATE,              -- NULLABLE: null while allocation is active
    status                    TEXT        NOT NULL, -- active / returned
    created_at                TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 6: asset_returns
-- Dependencies: asset_allocations, assets, employees
-- ============================================================
CREATE TABLE asset_returns (
    return_id                BIGSERIAL   PRIMARY KEY,
    allocation_id            BIGINT      NOT NULL REFERENCES asset_allocations(allocation_id) ON DELETE RESTRICT,
    asset_id                 BIGINT      NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    employee_id              BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    return_date              DATE        NOT NULL,
    verified_by_employee_id  BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    asset_condition          TEXT,
    remarks                  TEXT,
    created_at               TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 7: asset_repairs
-- Dependencies: assets, employees
-- ============================================================
CREATE TABLE asset_repairs (
    repair_id                BIGSERIAL   PRIMARY KEY,
    asset_id                 BIGINT      NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    reported_date            DATE        NOT NULL,
    reported_by_employee_id  BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    repair_date              DATE,
    repair_cost              NUMERIC,
    service_provider         TEXT,
    repair_status            TEXT        NOT NULL, -- pending / in_progress / completed
    remarks                  TEXT,
    created_at               TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 8: asset_approvals
-- Dependencies: assets, employees
-- ============================================================
CREATE TABLE asset_approvals (
    approval_id           BIGSERIAL   PRIMARY KEY,
    asset_id              BIGINT      NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    request_type          TEXT        NOT NULL, -- registration / disposal / repair
    approval_level        TEXT        NOT NULL, -- level_1 / level_2
    approver_employee_id  BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    approval_status       TEXT        NOT NULL, -- pending / approved / rejected
    approval_date         DATE,
    remarks               TEXT,
    created_at            TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 9: asset_disposals
-- Dependencies: assets, employees
-- ============================================================
CREATE TABLE asset_disposals (
    disposal_id               BIGSERIAL   PRIMARY KEY,
    asset_id                  BIGINT      NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    disposal_date             DATE        NOT NULL,
    disposal_method           TEXT        NOT NULL, -- sold / scrapped / donated / transferred
    disposal_value            NUMERIC,              -- NULLABLE: applicable for sold assets only
    approved_by_employee_id   BIGINT      NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    remarks                   TEXT,
    created_at                TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 10: audit_logs
-- Dependencies: none (polymorphic — no FK constraints)
-- ============================================================
CREATE TABLE audit_logs (
    audit_id    BIGSERIAL   PRIMARY KEY,
    table_name  TEXT        NOT NULL,
    record_id   BIGINT      NOT NULL,
    action_type TEXT        NOT NULL, -- INSERT / UPDATE / DELETE
    old_value   JSONB,                -- NULLABLE: null on INSERT
    new_value   JSONB,                -- NULLABLE: null on DELETE
    changed_by  TEXT        NOT NULL, -- employee_id or system
    changed_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

-- locations (1)
CREATE INDEX idx_locations_status
    ON locations(status);

-- employees (3)
CREATE INDEX idx_employees_location_id
    ON employees(location_id);

CREATE INDEX idx_employees_department_team
    ON employees(department_team);

CREATE INDEX idx_employees_status
    ON employees(status);

-- asset_categories (1)
CREATE INDEX idx_asset_categories_parent_category
    ON asset_categories(parent_category);

-- assets (3)
CREATE INDEX idx_assets_category_id
    ON assets(category_id);

CREATE INDEX idx_assets_location_id
    ON assets(location_id);

CREATE INDEX idx_assets_current_status
    ON assets(current_status);

-- asset_allocations (5)
CREATE INDEX idx_asset_allocations_asset_id
    ON asset_allocations(asset_id);

CREATE INDEX idx_asset_allocations_employee_id
    ON asset_allocations(employee_id);

CREATE INDEX idx_asset_allocations_allocated_by_employee_id
    ON asset_allocations(allocated_by_employee_id);

CREATE INDEX idx_asset_allocations_status
    ON asset_allocations(status);

CREATE INDEX idx_asset_allocations_expected_return_date
    ON asset_allocations(expected_return_date);

-- asset_returns (4)
CREATE INDEX idx_asset_returns_allocation_id
    ON asset_returns(allocation_id);

CREATE INDEX idx_asset_returns_asset_id
    ON asset_returns(asset_id);

CREATE INDEX idx_asset_returns_employee_id
    ON asset_returns(employee_id);

CREATE INDEX idx_asset_returns_verified_by_employee_id
    ON asset_returns(verified_by_employee_id);

-- asset_repairs (3)
CREATE INDEX idx_asset_repairs_asset_id
    ON asset_repairs(asset_id);

CREATE INDEX idx_asset_repairs_reported_by_employee_id
    ON asset_repairs(reported_by_employee_id);

CREATE INDEX idx_asset_repairs_repair_status
    ON asset_repairs(repair_status);

-- asset_approvals (4)
CREATE INDEX idx_asset_approvals_asset_id
    ON asset_approvals(asset_id);

CREATE INDEX idx_asset_approvals_approver_employee_id
    ON asset_approvals(approver_employee_id);

CREATE INDEX idx_asset_approvals_approval_status
    ON asset_approvals(approval_status);

CREATE INDEX idx_asset_approvals_request_type
    ON asset_approvals(request_type);

-- asset_disposals (3)
CREATE INDEX idx_asset_disposals_asset_id
    ON asset_disposals(asset_id);

CREATE INDEX idx_asset_disposals_approved_by_employee_id
    ON asset_disposals(approved_by_employee_id);

CREATE INDEX idx_asset_disposals_disposal_method
    ON asset_disposals(disposal_method);

-- audit_logs (4 — including 1 composite)
CREATE INDEX idx_audit_logs_table_name
    ON audit_logs(table_name);

CREATE INDEX idx_audit_logs_record_id
    ON audit_logs(record_id);

CREATE INDEX idx_audit_logs_changed_at
    ON audit_logs(changed_at);

CREATE INDEX idx_audit_logs_table_record
    ON audit_logs(table_name, record_id);

-- ============================================================
-- END OF MIGRATION
-- ============================================================
