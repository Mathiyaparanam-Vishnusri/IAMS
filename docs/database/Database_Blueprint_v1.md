---
name: project-blueprint-v1
description: "Core project context for Digitweb Lanka Inventory & Asset Management System — DB tables, lifecycle, approval workflow, known gaps"
metadata: 
  node_type: memory
  type: project
  originSessionId: 56cc8723-fa58-43df-8a14-3798ba609599
---

# Digitweb Lanka – Inventory & Asset Management System

**Status:** Draft v1 — moving toward GitHub structure → Supabase schema → Claude Code dev → Testing → Deployment

**Purpose:** Replace Excel-based inventory management with a centralized web app.

**Business Goal:** Track, allocate, return, repair, approve, and audit company assets.

## Source Files
- Inventory: `New 2026 Inventory Digitweb Lanka PVT(LTD).xlsx`
- Employees: `Digitweblanka Staffs Data.xlsx`

## Excel Categories (current)
Physical Stock, Repair Assets, Sold Assets, Accessories, IP Cameras, AC Service Information, Asset Allocation Information

## Database Tables (v1)
- **employees** — employee_id, full_name, location, designation, department_team
- **locations** — location_id, location_name, status
- **asset_categories** — category_id, category_name, parent_category, status
- **assets** — asset_id, asset_number, serial_number, invoice_number, item_name, category_id, brand, model, purchase_date, purchase_cost, location_id, current_status, remarks
- **asset_allocations** — allocation_id, asset_id, employee_id, allocated_date, allocated_by, allocation_condition, remarks, returned_date, status
- **asset_returns** — return_id, allocation_id, asset_id, employee_id, return_date, verified_by, asset_condition, remarks
- **asset_repairs** — repair_id, asset_id, reported_date, reported_by, repair_date, repair_cost, service_provider, repair_status, remarks
- **asset_approvals** — approval_id, asset_id, request_type, approval_level, approver_name, approval_status, approval_date, remarks
- **audit_logs** — audit_id, table_name, record_id, action_type, old_value, new_value, changed_by, changed_at

## Asset Lifecycle
Purchase → Received → Approval → Asset Registration → Available → Allocated → Returned → Available → Repair (optional) → Disposed

## Approval Workflow
- Asset Registration: Asset Received → Approval → Registration
- Asset Disposal: Level 1 (Arunkumar) → Level 2 (Management)

## Known Gaps (as of blueprint v1)
- Employee status field not available yet
- Employee joining date not available yet
- Official email not available yet
- Offboarding policy not yet defined
- Final approval hierarchy may change

## Pass/Fail Rules
**PASS:** DB supports full inventory lifecycle, approval workflow, asset history, audit trail
**FAIL:** Duplicate source of truth, lost asset history, hardcoded approval workflow

**Why:** These constraints define the architectural guardrails for all schema and feature decisions.
**How to apply:** Before suggesting schema changes or features, verify they don't violate FAIL conditions.
