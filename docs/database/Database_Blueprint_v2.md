# Database Blueprint v2

**Project:** Digitweb Lanka — Inventory & Asset Management System (IAMS)
**Version:** v2 — Approved for Schema Generation
**Date:** 2026-06-24
**Status:** APPROVED — SOURCE OF TRUTH FOR SUPABASE SCHEMA GENERATION
**Supersedes:** Database_Blueprint_v1.md
**Review Source:** Database_Blueprint_Review_v1.md

---

## Changes from v1 → v2

| # | Change | Type |
|---|--------|------|
| 1 | Added `asset_disposals` table | New table |
| 2 | `employees.location` renamed to `employees.location_id` | Field rename |
| 3 | `asset_allocations.allocated_by` → `allocated_by_employee_id` (FK) | FK conversion |
| 4 | `asset_returns.verified_by` → `verified_by_employee_id` (FK) | FK conversion |
| 5 | `asset_repairs.reported_by` → `reported_by_employee_id` (FK) | FK conversion |
| 6 | `asset_approvals.approver_name` → `approver_employee_id` (FK) | FK conversion |
| 7 | Added `expected_return_date` to `asset_allocations` | New field |
| 8 | Added `created_at` to `asset_allocations` | New field |
| 9 | Added `created_at` to `asset_returns` | New field |
| 10 | Added `created_at` to `asset_repairs` | New field |
| 11 | Added `created_at` to `asset_approvals` | New field |
| 12 | Deferred HR fields marked as nullable | Design intent clarified |

---

## Source Documents

- Inventory: `New 2026 Inventory Digitweb Lanka PVT(LTD).xlsx`
- Employees: `Digitweblanka Staffs Data.xlsx`

---

## Asset Lifecycle

```
Purchase → Received → Approval → Asset Registration → Available
→ Allocated → Returned → Available → Repair (optional) → Disposed
```

---

## Approval Workflow

- **Asset Registration:** Asset Received → Approval → Registration
- **Asset Disposal:** Level 1 (Arunkumar) → Level 2 (Management)

---

## Database Tables (v2)

### employees

Purpose: Store employee master information.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| employee_id | BIGSERIAL | PRIMARY KEY | |
| full_name | TEXT | NOT NULL | |
| location_id | BIGINT | FK → locations.location_id | Renamed from `location` in v1 |
| designation | TEXT | | |
| department_team | TEXT | | |
| status | TEXT | NULLABLE | DEFERRED — active / inactive / offboarded |
| joining_date | DATE | NULLABLE | DEFERRED — not yet available |
| email | TEXT | NULLABLE | DEFERRED — not yet available |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

> Deferred fields (status, joining_date, email) are included as nullable columns to avoid a future breaking migration when HR data becomes available.

---

### locations

Purpose: Store asset and employee locations.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| location_id | BIGSERIAL | PRIMARY KEY | |
| location_name | TEXT | NOT NULL | |
| status | TEXT | | active / inactive |
| created_at | TIMESTAMP | DEFAULT NOW() | |

---

### asset_categories

Purpose: Store asset categories with optional hierarchy.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| category_id | BIGSERIAL | PRIMARY KEY | |
| category_name | TEXT | NOT NULL | |
| parent_category | BIGINT | NULLABLE, FK → asset_categories.category_id | Self-referencing for hierarchy |
| status | TEXT | | active / inactive |

---

### assets

Purpose: Store all asset master records.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| asset_id | BIGSERIAL | PRIMARY KEY | |
| asset_number | TEXT | UNIQUE, NOT NULL | |
| serial_number | TEXT | | |
| invoice_number | TEXT | | |
| item_name | TEXT | NOT NULL | |
| category_id | BIGINT | FK → asset_categories.category_id | |
| brand | TEXT | | |
| model | TEXT | | |
| purchase_date | DATE | | |
| purchase_cost | NUMERIC | | |
| location_id | BIGINT | FK → locations.location_id | |
| current_status | TEXT | NOT NULL | available / allocated / repair / disposed |
| remarks | TEXT | | |
| created_at | TIMESTAMP | DEFAULT NOW() | |
| updated_at | TIMESTAMP | DEFAULT NOW() | |

---

### asset_allocations

Purpose: Store asset allocation history.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| allocation_id | BIGSERIAL | PRIMARY KEY | |
| asset_id | BIGINT | FK → assets.asset_id | |
| employee_id | BIGINT | FK → employees.employee_id | Recipient of the asset |
| allocated_date | DATE | NOT NULL | |
| allocated_by_employee_id | BIGINT | FK → employees.employee_id | Renamed from `allocated_by` in v1 |
| allocation_condition | TEXT | | condition at time of allocation |
| expected_return_date | DATE | NULLABLE | Added in v2 — supports overdue tracking |
| remarks | TEXT | | |
| returned_date | DATE | NULLABLE | |
| status | TEXT | NOT NULL | active / returned |
| created_at | TIMESTAMP | DEFAULT NOW() | Added in v2 |

---

### asset_returns

Purpose: Store asset return verification records.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| return_id | BIGSERIAL | PRIMARY KEY | |
| allocation_id | BIGINT | FK → asset_allocations.allocation_id | |
| asset_id | BIGINT | FK → assets.asset_id | |
| employee_id | BIGINT | FK → employees.employee_id | Employee returning the asset |
| return_date | DATE | NOT NULL | |
| verified_by_employee_id | BIGINT | FK → employees.employee_id | Renamed from `verified_by` in v1 |
| asset_condition | TEXT | | condition at time of return |
| remarks | TEXT | | |
| created_at | TIMESTAMP | DEFAULT NOW() | Added in v2 |

---

### asset_repairs

Purpose: Store asset repair history.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| repair_id | BIGSERIAL | PRIMARY KEY | |
| asset_id | BIGINT | FK → assets.asset_id | |
| reported_date | DATE | NOT NULL | |
| reported_by_employee_id | BIGINT | FK → employees.employee_id | Renamed from `reported_by` in v1 |
| repair_date | DATE | NULLABLE | |
| repair_cost | NUMERIC | NULLABLE | |
| service_provider | TEXT | NULLABLE | |
| repair_status | TEXT | NOT NULL | pending / in_progress / completed |
| remarks | TEXT | | |
| created_at | TIMESTAMP | DEFAULT NOW() | Added in v2 |

---

### asset_approvals

Purpose: Store approval workflow history.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| approval_id | BIGSERIAL | PRIMARY KEY | |
| asset_id | BIGINT | FK → assets.asset_id | |
| request_type | TEXT | NOT NULL | registration / disposal / repair |
| approval_level | TEXT | NOT NULL | level_1 / level_2 — kept as text, not enum, to support hierarchy changes |
| approver_employee_id | BIGINT | FK → employees.employee_id | Renamed from `approver_name` in v1 |
| approval_status | TEXT | NOT NULL | pending / approved / rejected |
| approval_date | DATE | NULLABLE | |
| remarks | TEXT | | |
| created_at | TIMESTAMP | DEFAULT NOW() | Added in v2 |

---

### asset_disposals

Purpose: Store asset disposal records. **New table added in v2.**

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| disposal_id | BIGSERIAL | PRIMARY KEY | |
| asset_id | BIGINT | FK → assets.asset_id | |
| disposal_date | DATE | NOT NULL | |
| disposal_method | TEXT | NOT NULL | sold / scrapped / donated / transferred |
| disposal_value | NUMERIC | NULLABLE | applicable for sold assets |
| approved_by_employee_id | BIGINT | FK → employees.employee_id | |
| remarks | TEXT | | |
| created_at | TIMESTAMP | DEFAULT NOW() | |

---

### audit_logs

Purpose: Store complete audit trail across all tables.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| audit_id | BIGSERIAL | PRIMARY KEY | |
| table_name | TEXT | NOT NULL | |
| record_id | BIGINT | NOT NULL | |
| action_type | TEXT | NOT NULL | INSERT / UPDATE / DELETE |
| old_value | JSONB | NULLABLE | |
| new_value | JSONB | NULLABLE | |
| changed_by | TEXT | NOT NULL | employee_id or system |
| changed_at | TIMESTAMP | DEFAULT NOW() | |

---

## Relationship Map

```
locations
  ├── employees.location_id          (FK)
  └── assets.location_id             (FK)

asset_categories
  ├── assets.category_id             (FK)
  └── asset_categories.parent_category (Self-referencing FK)

assets
  ├── asset_allocations.asset_id     (FK)
  ├── asset_returns.asset_id         (FK)
  ├── asset_repairs.asset_id         (FK)
  ├── asset_approvals.asset_id       (FK)
  └── asset_disposals.asset_id       (FK)

employees
  ├── asset_allocations.employee_id              (FK — recipient)
  ├── asset_allocations.allocated_by_employee_id (FK — allocator)
  ├── asset_returns.employee_id                  (FK — returner)
  ├── asset_returns.verified_by_employee_id      (FK — verifier)
  ├── asset_repairs.reported_by_employee_id      (FK — reporter)
  ├── asset_approvals.approver_employee_id       (FK — approver)
  └── asset_disposals.approved_by_employee_id    (FK — disposal approver)

asset_allocations
  └── asset_returns.allocation_id    (FK)

audit_logs
  └── polymorphic via table_name + record_id
```

---

## Deferred Fields

The following fields are defined in the `employees` table as nullable columns. They will be populated via a future data migration once the HR team provides source data.

| Field | Table | Condition for Population |
|-------|-------|--------------------------|
| `status` | `employees` | Offboarding policy defined |
| `joining_date` | `employees` | HR data extract available |
| `email` | `employees` | Official email list confirmed |

---

## Known Limitations

- Final approval hierarchy (levels and approvers) may change — kept flexible via text fields
- Offboarding policy not yet defined
- HR integration fields deferred

---

## Pass / Fail Rules

**PASS:**
- Database structure supports full inventory lifecycle including disposal
- Approval workflow supported via `asset_approvals`
- Full asset history maintained across all operational tables
- Audit trail supported via `audit_logs`
- All FK references use employee_id, not name strings

**FAIL:**
- Duplicate source of truth created
- Asset history lost
- Approval workflow hardcoded as enum
- Name strings used instead of FK references