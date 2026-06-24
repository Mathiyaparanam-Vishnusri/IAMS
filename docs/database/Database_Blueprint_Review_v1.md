# Database Blueprint Review v1

**Project:** Digitweb Lanka — Inventory & Asset Management System (IAMS)
**Reviewed:** 2026-06-24
**Status:** APPROVED WITH REQUIRED CHANGES

---

## 1. Approved Tables

All 9 tables from Blueprint v1 are approved to proceed into the Supabase schema.

| # | Table | Verdict |
|---|-------|---------|
| 1 | `employees` | Approved — partial fields pending HR data |
| 2 | `locations` | Approved |
| 3 | `asset_categories` | Approved |
| 4 | `assets` | Approved |
| 5 | `asset_allocations` | Approved with required changes |
| 6 | `asset_returns` | Approved with required changes |
| 7 | `asset_repairs` | Approved with required changes |
| 8 | `asset_approvals` | Approved with required changes |
| 9 | `audit_logs` | Approved |
| 10 | `asset_disposals` | **New — required addition** |

---

## 2. Approved Relationships

| Relationship | From | To | Type |
|---|---|---|---|
| Asset belongs to category | `assets.category_id` | `asset_categories.category_id` | FK |
| Asset located at | `assets.location_id` | `locations.location_id` | FK |
| Employee located at | `employees.location_id` | `locations.location_id` | FK |
| Category parent | `asset_categories.parent_category` | `asset_categories.category_id` | Self-referencing FK |
| Allocation references asset | `asset_allocations.asset_id` | `assets.asset_id` | FK |
| Allocation references employee | `asset_allocations.employee_id` | `employees.employee_id` | FK |
| Return references allocation | `asset_returns.allocation_id` | `asset_allocations.allocation_id` | FK |
| Return references asset | `asset_returns.asset_id` | `assets.asset_id` | FK |
| Return references employee | `asset_returns.employee_id` | `employees.employee_id` | FK |
| Repair references asset | `asset_repairs.asset_id` | `assets.asset_id` | FK |
| Approval references asset | `asset_approvals.asset_id` | `assets.asset_id` | FK |
| Disposal references asset | `asset_disposals.asset_id` | `assets.asset_id` | FK |
| Audit log polymorphic | `audit_logs.record_id` + `table_name` | Any table | Polymorphic |

---

## 3. Required Changes

These changes must be applied before the Supabase schema is created. No migration files should be created until all required changes are confirmed.

### 3.1 New Table: asset_disposals

The asset lifecycle documented in Blueprint v1 ends at Disposed, but no table exists to record disposal events. This table is required to complete the lifecycle.

**Fields required:**
- disposal_id (primary key)
- asset_id (FK → assets)
- disposal_date
- disposal_method (sold / scrapped / donated / transferred)
- disposal_value
- approved_by_employee_id (FK → employees)
- remarks
- created_at

### 3.2 Convert Name Strings to Foreign Keys

Four fields currently store employee names as plain text. These must be converted to foreign key references to maintain referential integrity, support reporting, and prevent data drift when employee names change.

| Table | Current Field | Required Field | FK Target |
|---|---|---|---|
| `asset_allocations` | `allocated_by` | `allocated_by_employee_id` | `employees.employee_id` |
| `asset_returns` | `verified_by` | `verified_by_employee_id` | `employees.employee_id` |
| `asset_repairs` | `reported_by` | `reported_by_employee_id` | `employees.employee_id` |
| `asset_approvals` | `approver_name` | `approver_employee_id` | `employees.employee_id` |

### 3.3 Add expected_return_date to asset_allocations

Without this field there is no way to identify overdue allocations or enforce return deadlines.

| Table | Field to Add | Type |
|---|---|---|
| `asset_allocations` | `expected_return_date` | DATE |

### 3.4 Add created_at Timestamps

Operational tables are missing record creation timestamps. Required for audit trail completeness and chronological reporting.

| Table | Field to Add |
|---|---|
| `asset_allocations` | `created_at` |
| `asset_returns` | `created_at` |
| `asset_repairs` | `created_at` |
| `asset_approvals` | `created_at` |
| `asset_disposals` | `created_at` (include at creation) |

### 3.5 Fix employees.location Field Name

The `employees` table uses `location` as a field name. This should be `location_id` to match the FK convention used in the `assets` table and to clearly indicate a foreign key reference.

| Table | Current Field | Required Field |
|---|---|---|
| `employees` | `location` | `location_id` |

---

## 4. Deferred Changes

These fields are acknowledged as gaps in Blueprint v1 but are deferred pending source data availability from the HR team.

| Field | Table | Reason for Deferral |
|---|---|---|
| `email` | `employees` | Official email not yet available |
| `joining_date` | `employees` | Joining date not yet available |
| `status` | `employees` | Employee status (active/inactive) pending HR process definition |
| HR integration fields | `employees` | Offboarding policy not yet defined |

These fields will be added via a future migration once HR data is confirmed. Schema must be designed to accept these fields without breaking existing records.

---

## 5. Risks

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | Name strings in 4 fields | If names change, historical records become unresolvable | Convert to FK before schema creation |
| 2 | No asset_disposals table | Disposed assets have no audit record — asset history is lost | Add table before schema creation |
| 3 | employees.location naming | Inconsistent FK naming causes confusion and potential ORM errors | Rename to location_id before schema creation |
| 4 | Approval hierarchy may change | approver_employee_id FK will need update if hierarchy restructures | Keep approval_level flexible (text, not enum) |
| 5 | Missing employee status | Active employees cannot be distinguished from inactive in allocation queries | Flag as deferred; add nullable column to schema |
| 6 | Deferred HR fields added later | Future ALTER TABLE on a populated table carries data risk | Design employees table with nullable columns for deferred fields from the start |

---

## 6. Final Recommendation

**Verdict: PROCEED WITH REQUIRED CHANGES**

Blueprint v1 provides a sound foundation. The 9 approved tables cover the core asset lifecycle. The relationships are logically correct. No duplicate sources of truth exist. The audit trail is in place.

Before the Supabase schema migration file is created, the following must be resolved in the schema design:

1. Add `asset_disposals` table
2. Rename 4 name-string fields to employee FK references
3. Add `expected_return_date` to `asset_allocations`
4. Add `created_at` to all operational tables
5. Rename `employees.location` to `employees.location_id`

Deferred HR fields should be added as nullable columns in the initial schema to avoid future breaking migrations.

Once these changes are incorporated, the schema is approved to proceed to Supabase migration file creation.
