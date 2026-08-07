# PostgreSQL Schema Documentation for NHIA Clinical Claims Intelligence Platform

This schema is built for PostgreSQL 17 and production-grade healthcare claims processing. It prioritizes normalization, append-only history, rule versioning, and extensibility for future NHIA and clinical audit workflows.

## Key design themes

- Business rule tables are versioned and time-bound so historical rule versions are preserved.
- Claims are modeled with structured diagnosis, medication, pricing, audit, penalty, and export data.
- Workflow history tables record status transitions, assignments, claim edits, and export events.
- Soft deletes preserve historical integrity for reference and master data.
- Search and analytics indexes are designed for large claim volumes, hospital tenancy, and audit reporting.

## Core tables

### hospitals
- Purpose: tenant root for hospital configuration and scoping.
- Columns: `hospital_id`, `code`, `name`, `address`, `timezone`, `default_currency`, `is_active`, `deleted_at`, `deleted_by`, timestamps.
- Notes: `code` is unique and required. Soft delete is supported with `deleted_at` and `deleted_by`.

### hospital_settings
- Purpose: versioned hospital configuration and deployable rule settings.
- Columns: `setting_key`, `setting_value`, `version`, `effective_from`, `effective_to`, `is_active`, `created_by`, `updated_by`, `deleted_at`, `deleted_by`, `metadata`.
- Notes: avoids overwriting hospital configuration and supports historical rollback or audits.

### user_roles
- Purpose: application role catalog.
- Columns: `code`, `name`, `description`, `is_active`, timestamps.
- Notes: allows role definition without enums.

### users
- Purpose: authenticated application actors.
- Columns: `hospital_id`, `user_role_id`, `username`, `email`, `full_name`, `department`, `password_hash`, lockout metadata, soft delete metadata, timestamps.
- Notes: usernames are unique per hospital and emails are globally unique.

### patients
- Purpose: optional patient registry for future claims linkage.
- Columns: hospital-scoped identifiers, demographics, contact fields, activity metadata, soft delete metadata, timestamps.
- Notes: optional patient association enables claim-level patient analytics later.

### drugs
- Purpose: canonical medication dictionary.
- Columns: `name`, `generic_name`, `brand_name`, `strength`, `dosage_form`, `route`, `rxnorm_code`, `snomed_code`, `atc_code`, `manufacturer`, `metadata`, soft delete metadata, timestamps.
- Notes: this table is ready for RxNorm and SNOMED integration.

### formulary_entries
- Purpose: versioned hospital formulary membership for drugs.
- Columns: `hospital_id`, `drug_id`, `version`, `effective_from`, `effective_to`, `is_active`, created/updated/deleted metadata, timestamps.
- Notes: preserves formulary history and prevents overwriting past coverage rules.

### icd_codes
- Purpose: ICD-10 master catalog.
- Columns: `code`, `description`, hierarchy fields, `billable`, activity flags, soft delete metadata, timestamps.
- Notes: supports hierarchical ICD relationships and billability metadata.

### icd_code_keywords
- Purpose: versioned keyword-to-ICD mappings.
- Columns: `icd_code_id`, `keyword_text`, `source`, `version`, `effective_from`, `effective_to`, `is_active`, created/updated/deleted metadata, timestamps.
- Notes: keyword rules are historical and hospital-independent by design. GIN trigram search supports large lookup workloads.

### gdrg_tariffs
- Purpose: versioned G-DRG pricing definitions.
- Columns: `hospital_id`, `icd_code_id`, `version`, `effective_from`, `effective_to`, `is_active`, `gdrg_code`, `gdrg_name`, `base_tariff`, `base_days`, `per_extra_day`, metadata, timestamps.
- Notes: preserves tariff history and supports global or hospital-specific overrides.

### addon_types
- Purpose: versioned add-on fee rules.
- Columns: `hospital_id`, `code`, `name`, `description`, `amount`, `amount_type`, versioning fields, metadata, timestamps.
- Notes: supports fixed and percentage add-ons.

### penalty_rules
- Purpose: versioned penalty rule definitions.
- Columns: `hospital_id`, `code`, `name`, `description`, `amount`, `amount_type`, versioning, metadata, timestamps.
- Notes: penalty rules are modeled as first-class configurable business rules.

### audit_levels
- Purpose: audit severity catalog.
- Columns: `code`, `name`, `description`, `sort_order`, `is_active`, timestamps.
- Notes: avoids hard-coded severity enums.

### audit_rules
- Purpose: versioned NHIA audit rule definitions.
- Columns: `hospital_id`, `rule_key`, `name`, `description`, `default_fix`, `audit_level_id`, `applies_to_diagnosis_keyword`, versioning fields, metadata, timestamps.
- Notes: every audit rule is preserved across versions.

### interactions
- Purpose: versioned drug/condition interaction and alert definitions.
- Columns: `hospital_id`, `interaction_code`, `name`, `description`, `severity`, versioning fields, metadata, timestamps.
- Notes: stores interaction rules with optional hospital-specific overrides.

### interaction_subject_types
- Purpose: subject classification for interaction rule participants.
- Columns: `code`, `name`, `description`, `is_active`, timestamps.

### interaction_subjects
- Purpose: link interactions to drugs or coded conditions.
- Columns: `interaction_id`, `interaction_subject_type_id`, `drug_id`, `condition_icd_code_id`, `subject_name`, timestamps.
- Notes: allows generic interaction subjects rather than fixed drug-pair tables.

### export_batch_statuses
- Purpose: batch export workflow statuses.
- Columns: `code`, `name`, `description`, `is_active`, timestamps.

### claim_export_batches
- Purpose: export batch header and file metadata.
- Columns: `hospital_id`, `created_by`, `name`, `export_batch_status_id`, `claim_count`, `total_amount`, file metadata, timestamps.
- Notes: supports export lifecycle tracking.

### claim_export_batch_claims
- Purpose: many-to-many claim membership for export batches.
- Columns: `claim_export_batch_id`, `claim_id`, `added_at`.

### claim_statuses
- Purpose: claim lifecycle state definitions.
- Columns: `code`, `name`, `description`, versioning, `sort_order`, `is_active`, timestamps.
- Notes: claim statuses are configurable and historical through versioned definitions.

### claims
- Purpose: clinical claim master record.
- Columns: `hospital_id`, `patient_id`, `claim_reference`, `current_status_id`, `created_by`, `assigned_to`, `assigned_at`, admission/discharge dates, `days_on_admission`, `primary_icd_code_id`, `raw_note`, `note_hash`, `extracted_diagnosis`, `discharge_summary`, `total_amount`, `estimated_payout`, `nhia_flags_count`, `tariff_breakdown`, `currency_code`, source metadata, activity flags, soft delete metadata, timestamps.
- Notes: current status is normalized with history recorded in `claim_status_history`.

### claim_diagnoses
- Purpose: structured diagnoses per claim.
- Columns: `claim_id`, `diagnosis_role_id`, `icd_code_id`, `diagnosis_text`, `rank`, `confidence_score`, `source`, `normalized`, timestamps.
- Notes: supports primary/secondary/admission/discharge/principal roles and ordering.

### claim_icd_mappings
- Purpose: ICD suggestion history for claim processing.
- Columns: `claim_id`, `icd_code_id`, optional `icd_code_keyword_id`, `keyword_text`, `is_primary`, `source`, `confidence_score`, timestamps.
- Notes: preserves mapping provenance.

### claim_medications
- Purpose: normalized medication extraction.
- Columns: `claim_id`, optional `drug_id`, optional `formulary_entry_id`, `raw_name`, `normalized_name`, `generic_name`, `brand_name`, `strength`, `dosage`, `frequency`, `route`, `normalized`, `confidence_score`, `source`, `is_on_formulary`, timestamps.
- Notes: prepares ingestion for RxNorm/SNOMED in the future.

### claim_charge_lines
- Purpose: structured billing components.
- Columns: `claim_id`, `claim_charge_line_type_id`, `description`, `unit_amount`, `quantity`, optional `related_gdrg_tariff_id`, `related_addon_type_id`, `related_penalty_rule_id`, `metadata`, timestamps.
- Notes: avoids free-text breakdowns and supports line-item analytics.

### claim_audit_flags
- Purpose: claim-specific NHIA audit findings.
- Columns: `claim_id`, optional `audit_rule_id`, `audit_level_id`, `issue`, `fix`, `revenue_at_risk`, `penalty_amount`, timestamps.
- Notes: links findings to rule definitions when available.

### claim_penalties
- Purpose: captured penalties applied to claims.
- Columns: `claim_id`, `penalty_rule_id`, `amount`, `description`, timestamps.

### claim_status_history
- Purpose: append-only claim status timeline.
- Columns: `claim_id`, `old_status_id`, `new_status_id`, `changed_by`, `changed_at`, `reason`, `metadata`.
- Notes: reconstructs every claim state transition.

### claim_assignment_history
- Purpose: assignment and reassignment history.
- Columns: `claim_id`, `old_assigned_to`, `new_assigned_to`, `assigned_by`, `assigned_at`, `reason`, `metadata`.

### claim_edit_history
- Purpose: claim field edits and corrections.
- Columns: `claim_id`, `edited_by`, `edited_at`, `field_name`, `old_value`, `new_value`, `reason`, `metadata`.

### claim_export_history
- Purpose: claim export lifecycle events.
- Columns: `claim_id`, optional `claim_export_batch_id`, `old_status_id`, `new_status_id`, `exported_by`, `exported_at`, `reason`, `metadata`.

### claim_reports
- Purpose: generated claim-level summaries and audit reports.
- Columns: `claim_id`, `claim_report_type_id`, `generated_by`, `generated_at`, `title`, `summary`, `report_data`, file metadata, timestamps.

### audit_log_events
- Purpose: generic application event trail.
- Columns: `hospital_id`, `user_id`, `action`, `target_type`, `target_id`, `claim_id`, `metadata`, `created_at`.
- Notes: append-only event logging with JSONB metadata for flexible query patterns.

## Indexing strategy

- `claims`: hospital/status/created_at composite index for common search patterns.
- `claims`: patient lookup, assignment lookup, admission/discharge timelines.
- `claim_diagnoses`: ICD and role search for audit and clinical review.
- `claim_medications`: drug lookup and raw-name text search for medication extraction.
- `icd_code_keywords`: trigram search on lowercased keywords for high-performance lookup.
- `drugs` and `patients`: trigram search for name-based discovery.
- `audit_log_events`: GIN index on metadata and common join columns.
- Versioned business rule tables: indexes on hospital, code, version, and effective dates.

## Versioning and history

- Every configurable rule table includes `version`, `effective_from`, `effective_to`, `is_active`, `created_by`, `updated_by`, and soft delete metadata.
- Historical changes are preserved by inserting new versions rather than updating past rows.
- Claim lifecycle changes are captured in dedicated history tables so the full state can be reconstructed.

## Healthcare domain balance

This schema supports:
- NHIA claim processing with diagnosis and medication normalization.
- Configurable G-DRG tariffs, add-on fees, and penalties.
- Clinical audit rule management and findings preservation.
- Batch export workflows with claim membership and export history.
- Patient association and future analytics across hospitals.
