# Migration Notes for NHIA Clinical Claims Intelligence Platform

This document explains how the existing application concepts map to the new PostgreSQL schema and why the redesign was made.

## Existing repository concepts mapped to the new schema

- `CLAIMS_BATCH` in `app.py` → `claim_export_batches` and `claim_export_batch_claims`.
- `process_note()` result objects → `claims`, `claim_diagnoses`, `claim_medications`, `claim_icd_mappings`, `claim_charge_lines`, `claim_audit_flags`, `claim_penalties`, `claim_reports`.
- `GDRG_TARIFF` → versioned `gdrg_tariffs`.
- `ADD_ONS` → versioned `addon_types`.
- `PENALTIES` → versioned `penalty_rules`.
- `NHIA_RULES` → versioned `audit_rules`.
- `FORMULARY` → versioned `formulary_entries` plus `drugs`.
- `ICD_KEYWORDS` → versioned `icd_code_keywords` plus `icd_codes`.
- `fake_login()` → `users` and `user_roles`.
- `HOSPITAL_NAME` → `hospitals` and `hospital_settings`.
- `audit.log_action()` prints → `audit_log_events`.

## New production capabilities

### Rule versioning

- `audit_rules`, `gdrg_tariffs`, `addon_types`, `penalty_rules`, `formulary_entries`, `hospital_settings`, `icd_code_keywords`, and `interactions` all preserve historical versions.
- This removes overwrite risk and enables auditability of business rules.

### Claim lifecycle history

- `claim_status_history` records every status change with old/new status, actor, timestamp, and reason.
- `claim_assignment_history` preserves assignment and reassignment events.
- `claim_edit_history` preserves every field-level claim correction or update.
- `claim_export_history` preserves export events at the claim level.

### Medication and diagnosis normalization

- `claim_medications` stores raw and normalized drug fields, route, dosage, frequency, and formulary references.
- `claim_diagnoses` stores role-aware diagnoses with rankings and ICD references.

### Clean clinical billing data

- `claim_charge_lines` stores structured pricing line items instead of a free-text tariff breakdown.
- This supports analytics, pricing changes, and future claims adjudication.

### Soft delete and audit safety

- Reference and master tables are soft deletable with `deleted_at` and `deleted_by`.
- This preserves historical integrity while preventing accidental data loss.

## Migration guidance

### ICD keyword migration

- Import `data/icd10_master.json` into `icd_codes` and create versioned rows in `icd_code_keywords`.
- Use `keyword_text` and `effective_from` to preserve the original keyword rule dataset.

### Existing tariff and penalty data

- Convert `GDRG_TARIFF` entries into `gdrg_tariffs` with `version = 1` and `effective_from` set to the initial deployment time.
- Convert `ADD_ONS` to `addon_types` and `PENALTIES` to `penalty_rules` similarly.

### Claims export migration

- Existing in-memory batches should be persisted into `claim_export_batches` and `claim_export_batch_claims`.
- Claim processing results should be persisted into `claims` plus child tables.

### Audit and rule history

- Future updates to rules should insert new rows with incremented `version` and updated `effective_from` instead of overwriting prior rows.
- Use the `is_active` field to mark the current active rule set when needed.

## Why this redesign was necessary

- The previous schema stored many rule sets as static or overwritten records.
- Billing breakdowns were embedded as text and not analyzable.
- Claim lifecycle state was conflated with a single status field and lacked reconstructable history.
- Medication and diagnosis data were not modeled for future RxNorm/SNOMED integration.
- The new design eliminates those weaknesses and is aligned with large-scale healthcare claims requirements.
