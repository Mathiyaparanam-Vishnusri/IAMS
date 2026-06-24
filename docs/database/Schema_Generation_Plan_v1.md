# Schema Generation Plan v1

**Project:** Digitweb Lanka — Inventory & Asset Management System (IAMS)
**Version:** v1
**Date:** 2026-06-24
**Status:** APPROVED FOR MIGRATION FILE CREATION
**Source:** Database_Blueprint_v2.md

---

## Purpose

This document defines the exact sequence, dependencies, indexes, and risk considerations required to generate the Supabase SQL migration file from Database_Blueprint_v2.md. It is the bridge between the blueprint and the migration file.

---

## 1. All 10 Tables

| # | Table | Role |
|---|-------|------|
| 1 | `locations` | Reference — no dependencies |
| 2 | `employees` | Master — depends on locations |
| 3 | `asset_categories` | Reference — self-referencing |
| 4 | `assets` | Master — depends on locations, asset_categories |
| 5 | `asset_allocations` | Operational — depends on assets, employees |
| 6 | `asset_returns` | Operational — depends on asset_allocations, assets, employees |
| 7 | `asset_repairs` | Operational — depends on assets, employees |
| 8 | `asset_approvals` | Operational — depends on assets, employees |
| 9 | `asset_disposals` | Operational — depends on assets, employees |
| 10 | `audit_logs` | System — polymorphic, no FK dependencies |

---

## 2. Primary Keys

| Table | Primary Key | Type |
|-------|------------|------|
| `locations` | `location_id` | BIGSERIAL |
| `employees` | `employee_id` | BIGSERIAL |
| `asset_categories` | `category_id` | BIGSERIAL |
| `assets` | `asset_id` | BIGSERIAL |
| `asset_allocations` | `allocation_id` | BIGSERIAL |
| `asset_returns` | `return_id` | BIGSERIAL |
| `asset_repairs` | `repair_id` | BIGSERIAL |
| `asset_approvals` | `approval_id` | BIGSERIAL |
| `asset_disposals` | `disposal_id` | BIGSERIAL |
| `audit_logs` | `audit_id` | BIGSERIAL |

All primary keys use BIGSERIAL for auto-increment compatibility with Supabase.

---

## 3. Foreign Keys

| FK Field | Table | References | On Delete |
|----------|-------|------------|-----------|
| `location_id` | `employees` | `locations.location_id` | SET NULL |
| `location_id` | `assets` | `locations.location_id` | SET NULL |
| `category_id` | `assets` | `asset_categories.category_id` | SET NULL |
| `parent_category` | `asset_categories` | `asset_categories.category_id` | SET NULL |
| `asset_id` | `asset_allocations` | `assets.asset_id` | RESTRICT |
| `employee_id` | `asset_allocations` | `employees.employee_id` | RESTRICT |
| `allocated_by_employee_id` | `asset_allocations` | `employees.employee_id` | RESTRICT |
| `allocation_id` | `asset_returns` | `asset_allocations.allocation_id` | RESTRICT |
| `asset_id` | `asset_returns` | `assets.asset_id` | RESTRICT |
| `employee_id` | `asset_returns` | `employees.employee_id` | RESTRICT |
| `verified_by_employee_id` | `asset_returns` | `employees.employee_id` | RESTRICT |
| `asset_id` | `asset_repairs` | `assets.asset_id` | RESTRICT |
| `reported_by_employee_id` | `asset_repairs` | `employees.employee_id` | RESTRICT |
| `asset_id` | `asset_approvals` | `assets.asset_id` | RESTRICT |
| `approver_employee_id` | `asset_approvals` | `employees.employee_id` | RESTRICT |
| `asset_id` | `asset_disposals` | `assets.asset_id` | RESTRICT |
| `approved_by_employee_id` | `asset_disposals` | `employees.employee_id` | RESTRICT |

**On Delete rules:**
- `SET NULL` — used for reference tables (locations, categories) where deleting a location should not cascade to all assets
- `RESTRICT` — used for all operational records to prevent deletion of employees or assets that have history

---

## 4. Table Creation Order

Tables must be created in dependency order. A table cannot be created before the table it references.

```
Step 1  →  locations
Step 2  →  employees
Step 3  →  asset_categories
Step 4  →  assets
Step 5  →  asset_allocations
Step 6  →  asset_returns
Step 7  →  asset_repairs
Step 8  →  asset_approvals
Step 9  →  asset_disposals
Step 10 →  audit_logs
```

---

## 5. Dependency Order

| Table | Depends On |
|-------|-----------|
| `locations` | None |
| `employees` | `locations` |
| `asset_categories` | `asset_categories` (self — parent_category nullable, safe) |
| `assets` | `locations`, `asset_categories` |
| `asset_allocations` | `assets`, `employees` |
| `asset_returns` | `asset_allocations`, `assets`, `employees` |
| `asset_repairs` | `assets`, `employees` |
| `asset_approvals` | `assets`, `employees` |
| `asset_disposals` | `assets`, `employees` |
| `audit_logs` | None (polymorphic — no FK) |

`audit_logs` has no FK dependencies and can be created at any step, but placing it last keeps the migration logically grouped.

---

## 6. Required Indexes

Indexes are required on all FK columns and commonly queried filter columns.

### locations
| Index | Column | Reason |
|-------|--------|--------|
| PK | `location_id` | Auto-created |
| IDX | `status` | Filter active/inactive locations |

### employees
| Index | Column | Reason |
|-------|--------|--------|
| PK | `employee_id` | Auto-created |
| IDX | `location_id` | FK lookup |
| IDX | `department_team` | Filter by department |
| IDX | `status` | Filter active employees (deferred — add when status is populated) |

### asset_categories
| Index | Column | Reason |
|-------|--------|--------|
| PK | `category_id` | Auto-created |
| IDX | `parent_category` | Hierarchy traversal |

### assets
| Index | Column | Reason |
|-------|--------|--------|
| PK | `asset_id` | Auto-created |
| UNIQUE | `asset_number` | Enforced uniqueness |
| IDX | `category_id` | FK lookup |
| IDX | `location_id` | FK lookup |
| IDX | `current_status` | Most common filter — available / allocated / repair / disposed |

### asset_allocations
| Index | Column | Reason |
|-------|--------|--------|
| PK | `allocation_id` | Auto-created |
| IDX | `asset_id` | FK lookup |
| IDX | `employee_id` | Filter by employee |
| IDX | `allocated_by_employee_id` | FK lookup |
| IDX | `status` | Filter active allocations |
| IDX | `expected_return_date` | Overdue detection queries |

### asset_returns
| Index | Column | Reason |
|-------|--------|--------|
| PK | `return_id` | Auto-created |
| IDX | `allocation_id` | FK lookup |
| IDX | `asset_id` | FK lookup |
| IDX | `employee_id` | FK lookup |
| IDX | `verified_by_employee_id` | FK lookup |

### asset_repairs
| Index | Column | Reason |
|-------|--------|--------|
| PK | `repair_id` | Auto-created |
| IDX | `asset_id` | FK lookup |
| IDX | `reported_by_employee_id` | FK lookup |
| IDX | `repair_status` | Filter pending / in_progress / completed |

### asset_approvals
| Index | Column | Reason |
|-------|--------|--------|
| PK | `approval_id` | Auto-created |
| IDX | `asset_id` | FK lookup |
| IDX | `approver_employee_id` | FK lookup |
| IDX | `approval_status` | Filter pending approvals |
| IDX | `request_type` | Filter by type |

### asset_disposals
| Index | Column | Reason |
|-------|--------|--------|
| PK | `disposal_id` | Auto-created |
| IDX | `asset_id` | FK lookup |
| IDX | `approved_by_employee_id` | FK lookup |
| IDX | `disposal_method` | Filter by method |

### audit_logs
| Index | Column | Reason |
|-------|--------|--------|
| PK | `audit_id` | Auto-created |
| IDX | `table_name` | Filter logs by table |
| IDX | `record_id` | Lookup all events for a specific record |
| IDX | `changed_at` | Chronological audit queries |
| COMPOSITE | `table_name + record_id` | Combined lookup — most common audit query pattern |

---

## 7. Nullable Fields

Fields marked nullable may have no value at creation time.

| Table | Nullable Field | Reason |
|-------|---------------|--------|
| `employees` | `location_id` | Employee may not have a fixed location |
| `employees` | `designation` | May be unknown at import |
| `employees` | `department_team` | May be unknown at import |
| `employees` | `status` | DEFERRED |
| `employees` | `joining_date` | DEFERRED |
| `employees` | `email` | DEFERRED |
| `asset_categories` | `parent_category` | Top-level categories have no parent |
| `assets` | `serial_number` | Not all assets have serial numbers |
| `assets` | `invoice_number` | May not be available for older assets |
| `assets` | `category_id` | Allow uncategorized assets at import |
| `assets` | `location_id` | May be unassigned |
| `assets` | `purchase_date` | May be unknown for legacy assets |
| `assets` | `purchase_cost` | May be unknown for legacy assets |
| `assets` | `brand` | Not applicable to all asset types |
| `assets` | `model` | Not applicable to all asset types |
| `assets` | `remarks` | Optional |
| `asset_allocations` | `expected_return_date` | Permanent allocations may have no return date |
| `asset_allocations` | `returned_date` | Null while allocation is active |
| `asset_allocations` | `remarks` | Optional |
| `asset_returns` | `asset_condition` | May be recorded separately |
| `asset_returns` | `remarks` | Optional |
| `asset_repairs` | `repair_date` | Unknown at time of reporting |
| `asset_repairs` | `repair_cost` | Unknown until repair is completed |
| `asset_repairs` | `service_provider` | May be internal repair |
| `asset_repairs` | `remarks` | Optional |
| `asset_approvals` | `approval_date` | Null while pending |
| `asset_approvals` | `remarks` | Optional |
| `asset_disposals` | `disposal_value` | Null for scrapped or donated assets |
| `asset_disposals` | `remarks` | Optional |
| `audit_logs` | `old_value` | Null on INSERT |
| `audit_logs` | `new_value` | Null on DELETE |

---

## 8. Deferred HR Fields

These fields exist in the `employees` table as nullable columns from the initial migration. They are intentionally empty until HR data is confirmed.

| Field | Type | Nullable | Population Trigger |
|-------|------|----------|--------------------|
| `status` | TEXT | YES | Offboarding policy defined by HR |
| `joining_date` | DATE | YES | HR data extract delivered |
| `email` | TEXT | YES | Official email list confirmed |

No ALTER TABLE operation will be required when these fields are populated — they are already present in the schema. A data migration (UPDATE statements) will populate them when the source data is available.

---

## 9. Risks During Migration

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | Creating tables out of dependency order | HIGH | Follow Step 1–10 creation sequence exactly |
| 2 | Dropping and recreating tables to fix errors | HIGH | Test migration in a Supabase staging project before production |
| 3 | `asset_categories.parent_category` self-reference | MEDIUM | Create table first with nullable parent_category; FK added after table exists |
| 4 | Importing existing Excel data with name strings into FK fields | HIGH | Must map employee names to employee_id values before import |
| 5 | `assets.current_status` values not matching expected values | MEDIUM | Validate source Excel values against allowed status list before import |
| 6 | Duplicate asset_number values in Excel source | MEDIUM | Deduplicate source before import — `asset_number` has UNIQUE constraint |
| 7 | Legacy assets missing category, location, or cost | LOW | Fields are nullable — missing values will not block import |
| 8 | `audit_logs.changed_by` type mismatch | LOW | `changed_by` is TEXT not FK — accepts both employee_id and system values |
| 9 | Supabase RLS policies blocking inserts | MEDIUM | Disable RLS or configure insert policies before running seed data |
| 10 | Running migration on production before testing | HIGH | Always run on staging first; validate row counts after each table |

---

## 10. Recommended Migration Sequence

### Phase 1 — Schema Creation (Migration File)
1. Create `locations`
2. Create `employees` (with nullable deferred HR fields)
3. Create `asset_categories` (self-referencing FK added inline)
4. Create `assets`
5. Create `asset_allocations`
6. Create `asset_returns`
7. Create `asset_repairs`
8. Create `asset_approvals`
9. Create `asset_disposals`
10. Create `audit_logs`
11. Create all indexes

### Phase 2 — Reference Data Seed
1. Insert location records from source Excel
2. Insert employee records (name, location_id, designation, department_team)
3. Insert asset category records (parent categories first, then child categories)

### Phase 3 — Asset Master Data Import
1. Map category names to category_id values
2. Map location names to location_id values
3. Insert asset records from source Excel

### Phase 4 — Historical Operational Data Import (if required)
1. Map employee names to employee_id values in source data
2. Insert asset_allocation history
3. Insert asset_return history
4. Insert asset_repair history
5. Insert asset_approval history

### Phase 5 — Validation
1. Verify row counts per table match source Excel
2. Verify no orphaned FK references
3. Verify `assets.current_status` values are valid
4. Verify all active allocations have no returned_date
5. Verify audit_logs captures initial imports (if triggers are enabled)

### Phase 6 — Deferred HR Fields (future)
1. Receive HR data extract
2. Map employee records by employee_id
3. Run UPDATE to populate status, joining_date, email
4. Validate completeness

---

## Migration Readiness Checklist

| Item | Status |
|------|--------|
| All 10 tables defined in Blueprint v2 | READY |
| Table creation order confirmed | READY |
| FK on-delete behaviour decided | READY |
| All required indexes listed | READY |
| Nullable fields documented | READY |
| Deferred HR fields handled safely | READY |
| Risk register complete | READY |
| Migration sequence documented | READY |
| Staging-first policy confirmed | READY |
| Source Excel data mapping required before import | PENDING — data mapping step |
