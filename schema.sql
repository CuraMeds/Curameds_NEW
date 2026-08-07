-- Production-ready PostgreSQL 17 schema for NHIA Clinical Claims Intelligence Platform
-- Fully normalized, versioned business rules, append-only history, and healthcare domain model.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE claim_statuses (
    claim_status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    version INT NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_claim_statuses_code_version UNIQUE (code, version),
    CONSTRAINT chk_claim_statuses_code_not_empty CHECK (code <> ''),
    CONSTRAINT chk_claim_statuses_name_not_empty CHECK (name <> '')
);

CREATE TABLE export_batch_statuses (
    export_batch_status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE claim_report_types (
    claim_report_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE diagnosis_roles (
    diagnosis_role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE interaction_subject_types (
    interaction_subject_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE claim_charge_line_types (
    claim_charge_line_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE hospitals (
    hospital_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Africa/Lagos',
    default_currency CHAR(3) NOT NULL DEFAULT 'NGN',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_hospitals_code_not_empty CHECK (code <> ''),
    CONSTRAINT chk_hospitals_name_not_empty CHECK (name <> '')
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    user_role_id UUID NOT NULL,
    username VARCHAR(128) NOT NULL,
    email VARCHAR(320),
    full_name VARCHAR(255),
    department VARCHAR(128),
    password_hash TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    failed_login_attempts INT NOT NULL DEFAULT 0 CHECK (failed_login_attempts >= 0),
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_users_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_users_role FOREIGN KEY (user_role_id) REFERENCES user_roles (user_role_id) ON DELETE RESTRICT,
    CONSTRAINT fk_users_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_users_hospital_username UNIQUE (hospital_id, username),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_username_not_empty CHECK (username <> '')
);

CREATE INDEX idx_users_hospital_id ON users (hospital_id);
-- user indexes defined earlier

CREATE TABLE hospital_settings (
    hospital_setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    setting_key VARCHAR(128) NOT NULL,
    setting_value TEXT NOT NULL,
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_hospital_settings_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_hospital_settings_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_hospital_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_hospital_settings_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_hospital_settings_key_version UNIQUE (hospital_id, setting_key, version),
    CONSTRAINT chk_hospital_settings_key_not_empty CHECK (setting_key <> ''),
    CONSTRAINT chk_hospital_settings_value_not_empty CHECK (setting_value <> '')
);


CREATE TABLE patients (
    patient_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    external_patient_id VARCHAR(64),
    medical_record_number VARCHAR(64),
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(32),
    phone_number VARCHAR(32),
    email VARCHAR(320),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_patients_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_patients_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_patients_full_name_not_empty CHECK (full_name <> ''),
    CONSTRAINT chk_patients_gender_values CHECK (gender IS NULL OR gender IN ('male', 'female', 'other', 'unknown'))
);

CREATE TABLE drugs (
    drug_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    generic_name VARCHAR(255),
    brand_name VARCHAR(255),
    strength VARCHAR(64),
    dosage_form VARCHAR(128),
    route VARCHAR(128),
    rxnorm_code VARCHAR(64),
    snomed_code VARCHAR(64),
    atc_code VARCHAR(16),
    manufacturer VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_drugs_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_drugs_name_not_empty CHECK (name <> '')
);

CREATE TABLE formulary_entries (
    formulary_entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    drug_id UUID NOT NULL,
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_formulary_entries_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_formulary_entries_drug FOREIGN KEY (drug_id) REFERENCES drugs (drug_id) ON DELETE RESTRICT,
    CONSTRAINT fk_formulary_entries_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_formulary_entries_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_formulary_entries_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_formulary_entries_hospital_drug_version UNIQUE (hospital_id, drug_id, version)
);

CREATE TABLE icd_codes (
    icd_code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(16) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    chapter VARCHAR(64),
    block VARCHAR(64),
    category VARCHAR(64),
    parent_icd_code_id UUID,
    billable BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_icd_codes_parent FOREIGN KEY (parent_icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT fk_icd_codes_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_icd_codes_code_not_empty CHECK (code <> ''),
    CONSTRAINT chk_icd_codes_description_not_empty CHECK (description <> '')
);

CREATE TABLE icd_code_keywords (
    icd_code_keyword_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    icd_code_id UUID NOT NULL,
    keyword_text TEXT NOT NULL,
    source VARCHAR(128),
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_icd_code_keywords_icd FOREIGN KEY (icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE CASCADE,
    CONSTRAINT fk_icd_code_keywords_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_icd_code_keywords_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_icd_code_keywords_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_icd_code_keywords_version UNIQUE (icd_code_id, keyword_text, version),
    CONSTRAINT chk_icd_code_keywords_keyword_not_empty CHECK (keyword_text <> '')
);

CREATE TABLE gdrg_tariffs (
    gdrg_tariff_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID,
    icd_code_id UUID NOT NULL,
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    gdrg_code VARCHAR(32) NOT NULL,
    gdrg_name VARCHAR(255) NOT NULL,
    base_tariff NUMERIC(14,2) NOT NULL CHECK (base_tariff >= 0),
    base_days INT NOT NULL CHECK (base_days >= 0),
    per_extra_day NUMERIC(14,2) NOT NULL CHECK (per_extra_day >= 0),
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_gdrg_tariffs_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_gdrg_tariffs_icd FOREIGN KEY (icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT fk_gdrg_tariffs_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_gdrg_tariffs_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_gdrg_tariffs_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_gdrg_tariffs_version UNIQUE (hospital_id, icd_code_id, version),
    CONSTRAINT chk_gdrg_tariffs_effective_window CHECK (effective_to IS NULL OR effective_to > effective_from)
);

CREATE TABLE addon_types (
    addon_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    amount_type VARCHAR(16) NOT NULL DEFAULT 'fixed',
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_addon_types_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_addon_types_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_addon_types_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_addon_types_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_addon_types_version UNIQUE (hospital_id, code, version),
    CONSTRAINT chk_addon_types_code_not_empty CHECK (code <> ''),
    CONSTRAINT chk_addon_types_name_not_empty CHECK (name <> ''),
    CONSTRAINT chk_addon_types_amount_type CHECK (amount_type IN ('fixed', 'percentage'))
);

CREATE TABLE penalty_rules (
    penalty_rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    amount_type VARCHAR(16) NOT NULL DEFAULT 'fixed',
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_penalty_rules_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_penalty_rules_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_penalty_rules_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_penalty_rules_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_penalty_rules_version UNIQUE (hospital_id, code, version),
    CONSTRAINT chk_penalty_rules_code_not_empty CHECK (code <> ''),
    CONSTRAINT chk_penalty_rules_name_not_empty CHECK (name <> ''),
    CONSTRAINT chk_penalty_rules_amount_type CHECK (amount_type IN ('fixed', 'percentage'))
);

CREATE TABLE audit_levels (
    audit_level_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_rules (
    audit_rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID,
    rule_key VARCHAR(128) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    default_fix TEXT NOT NULL,
    audit_level_id UUID NOT NULL,
    applies_to_diagnosis_keyword TEXT,
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_audit_rules_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_rules_level FOREIGN KEY (audit_level_id) REFERENCES audit_levels (audit_level_id) ON DELETE RESTRICT,
    CONSTRAINT fk_audit_rules_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_rules_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_rules_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_audit_rules_version UNIQUE (hospital_id, rule_key, version),
    CONSTRAINT chk_audit_rules_rule_key_not_empty CHECK (rule_key <> ''),
    CONSTRAINT chk_audit_rules_name_not_empty CHECK (name <> '')
);

CREATE TABLE interactions (
    interaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID,
    interaction_code VARCHAR(128) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(32) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_interactions_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_interactions_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_interactions_updated_by FOREIGN KEY (updated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_interactions_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_interactions_version UNIQUE (hospital_id, interaction_code, version),
    CONSTRAINT chk_interactions_interaction_code_not_empty CHECK (interaction_code <> ''),
    CONSTRAINT chk_interactions_name_not_empty CHECK (name <> ''),
    CONSTRAINT chk_interactions_severity_not_empty CHECK (severity <> '')
);

CREATE TABLE interaction_subjects (
    interaction_subject_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interaction_id UUID NOT NULL,
    interaction_subject_type_id UUID NOT NULL,
    drug_id UUID,
    condition_icd_code_id UUID,
    subject_name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_interaction_subjects_interaction FOREIGN KEY (interaction_id) REFERENCES interactions (interaction_id) ON DELETE CASCADE,
    CONSTRAINT fk_interaction_subjects_type FOREIGN KEY (interaction_subject_type_id) REFERENCES interaction_subject_types (interaction_subject_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_interaction_subjects_drug FOREIGN KEY (drug_id) REFERENCES drugs (drug_id) ON DELETE RESTRICT,
    CONSTRAINT fk_interaction_subjects_condition_icd FOREIGN KEY (condition_icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT chk_interaction_subjects_subject CHECK (
        (drug_id IS NOT NULL AND condition_icd_code_id IS NULL) OR
        (drug_id IS NULL AND condition_icd_code_id IS NOT NULL)
    ),
    CONSTRAINT chk_interaction_subjects_name_not_empty CHECK (subject_name <> '' OR condition_icd_code_id IS NOT NULL)
);

CREATE TABLE claim_export_batches (
    claim_export_batch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    created_by UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    export_batch_status_id UUID NOT NULL,
    claim_count INT NOT NULL DEFAULT 0 CHECK (claim_count >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    file_name VARCHAR(255),
    file_path TEXT,
    file_size_bytes BIGINT,
    exported_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_export_batches_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_export_batches_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_export_batches_status FOREIGN KEY (export_batch_status_id) REFERENCES export_batch_statuses (export_batch_status_id) ON DELETE RESTRICT,
    CONSTRAINT uq_claim_export_batches_hospital_name UNIQUE (hospital_id, name),
    CONSTRAINT chk_claim_export_batches_name_not_empty CHECK (name <> '')
);

CREATE TABLE claims (
    claim_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    patient_id UUID,
    claim_reference VARCHAR(64),
    current_status_id UUID NOT NULL,
    created_by UUID NOT NULL,
    assigned_to UUID,
    assigned_at TIMESTAMPTZ,
    admission_date DATE,
    discharge_date DATE,
    days_on_admission INT NOT NULL DEFAULT 1 CHECK (days_on_admission >= 1),
    primary_icd_code_id UUID,
    raw_note TEXT NOT NULL,
    note_hash CHAR(64) NOT NULL,
    extracted_diagnosis TEXT NOT NULL,
    discharge_summary TEXT,
    total_amount NUMERIC(14,2) NOT NULL CHECK (total_amount >= 0),
    estimated_payout NUMERIC(14,2) NOT NULL CHECK (estimated_payout >= 0),
    nhia_flags_count INT NOT NULL DEFAULT 0 CHECK (nhia_flags_count >= 0),
    tariff_breakdown TEXT,
    currency_code CHAR(3) NOT NULL DEFAULT 'NGN',
    source_system VARCHAR(128),
    source_reference VARCHAR(128),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ,
    exported_at TIMESTAMPTZ,
    last_reviewed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claims_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_claims_patient FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE SET NULL,
    CONSTRAINT fk_claims_status FOREIGN KEY (current_status_id) REFERENCES claim_statuses (claim_status_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claims_created_by FOREIGN KEY (created_by) REFERENCES users (user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claims_assigned_to FOREIGN KEY (assigned_to) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_claims_primary_icd FOREIGN KEY (primary_icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claims_deleted_by FOREIGN KEY (deleted_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT uq_claims_hospital_reference UNIQUE (hospital_id, claim_reference),
    CONSTRAINT chk_claims_raw_note_not_empty CHECK (raw_note <> ''),
    CONSTRAINT chk_claims_note_hash_length CHECK (length(note_hash) = 64),
    CONSTRAINT chk_claims_admission_discharge_dates CHECK (discharge_date IS NULL OR admission_date IS NULL OR discharge_date >= admission_date)
);

CREATE TABLE claim_diagnoses (
    claim_diagnosis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    diagnosis_role_id UUID NOT NULL,
    icd_code_id UUID,
    diagnosis_text TEXT NOT NULL,
    rank INT NOT NULL DEFAULT 1 CHECK (rank >= 1),
    confidence_score NUMERIC(5,4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    source TEXT,
    normalized BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_diagnoses_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_diagnoses_role FOREIGN KEY (diagnosis_role_id) REFERENCES diagnosis_roles (diagnosis_role_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_diagnoses_icd FOREIGN KEY (icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT uq_claim_diagnoses_claim_role_rank UNIQUE (claim_id, diagnosis_role_id, rank),
    CONSTRAINT chk_claim_diagnoses_text_not_empty CHECK (diagnosis_text <> '')
);

CREATE TABLE claim_icd_mappings (
    claim_icd_mapping_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    icd_code_id UUID NOT NULL,
    icd_code_keyword_id UUID,
    keyword_text TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    source VARCHAR(128),
    confidence_score NUMERIC(5,4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_icd_mappings_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_icd_mappings_icd FOREIGN KEY (icd_code_id) REFERENCES icd_codes (icd_code_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_icd_mappings_keyword FOREIGN KEY (icd_code_keyword_id) REFERENCES icd_code_keywords (icd_code_keyword_id) ON DELETE SET NULL,
    CONSTRAINT uq_claim_icd_mappings_claim_icd UNIQUE (claim_id, icd_code_id),
    CONSTRAINT chk_claim_icd_mappings_keyword_not_empty CHECK (keyword_text <> '')
);

CREATE TABLE claim_medications (
    claim_medication_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    drug_id UUID,
    formulary_entry_id UUID,
    raw_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255),
    generic_name VARCHAR(255),
    brand_name VARCHAR(255),
    strength VARCHAR(64),
    dosage VARCHAR(64),
    frequency VARCHAR(64),
    route VARCHAR(64),
    normalized BOOLEAN NOT NULL DEFAULT FALSE,
    confidence_score NUMERIC(5,4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    source VARCHAR(128),
    is_on_formulary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_medications_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_medications_drug FOREIGN KEY (drug_id) REFERENCES drugs (drug_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_medications_formulary FOREIGN KEY (formulary_entry_id) REFERENCES formulary_entries (formulary_entry_id) ON DELETE SET NULL,
    CONSTRAINT uq_claim_medications_claim_raw_name UNIQUE (claim_id, raw_name),
    CONSTRAINT chk_claim_medications_raw_name_not_empty CHECK (raw_name <> '')
);

CREATE TABLE claim_charge_lines (
    claim_charge_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    claim_charge_line_type_id UUID NOT NULL,
    description TEXT NOT NULL,
    unit_amount NUMERIC(14,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity >= 1),
    related_gdrg_tariff_id UUID,
    related_addon_type_id UUID,
    related_penalty_rule_id UUID,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_charge_lines_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_charge_lines_type FOREIGN KEY (claim_charge_line_type_id) REFERENCES claim_charge_line_types (claim_charge_line_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_charge_lines_gdrg FOREIGN KEY (related_gdrg_tariff_id) REFERENCES gdrg_tariffs (gdrg_tariff_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_charge_lines_addon FOREIGN KEY (related_addon_type_id) REFERENCES addon_types (addon_type_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_charge_lines_penalty FOREIGN KEY (related_penalty_rule_id) REFERENCES penalty_rules (penalty_rule_id) ON DELETE SET NULL,
    CONSTRAINT chk_claim_charge_lines_description_not_empty CHECK (description <> '')
);

CREATE TABLE claim_audit_flags (
    claim_audit_flag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    audit_rule_id UUID,
    audit_level_id UUID NOT NULL,
    issue TEXT NOT NULL,
    fix TEXT NOT NULL,
    revenue_at_risk NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (revenue_at_risk >= 0),
    penalty_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (penalty_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_audit_flags_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_audit_flags_rule FOREIGN KEY (audit_rule_id) REFERENCES audit_rules (audit_rule_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_audit_flags_level FOREIGN KEY (audit_level_id) REFERENCES audit_levels (audit_level_id) ON DELETE RESTRICT,
    CONSTRAINT chk_claim_audit_flags_issue_not_empty CHECK (issue <> ''),
    CONSTRAINT chk_claim_audit_flags_fix_not_empty CHECK (fix <> '')
);

CREATE TABLE claim_penalties (
    claim_penalty_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    penalty_rule_id UUID NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_penalties_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_penalties_rule FOREIGN KEY (penalty_rule_id) REFERENCES penalty_rules (penalty_rule_id) ON DELETE RESTRICT,
    CONSTRAINT chk_claim_penalties_description_not_empty CHECK (description <> '')
);

CREATE TABLE claim_export_batch_claims (
    claim_export_batch_claim_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_export_batch_id UUID NOT NULL,
    claim_id UUID NOT NULL,
    added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_export_batch_claims_batch FOREIGN KEY (claim_export_batch_id) REFERENCES claim_export_batches (claim_export_batch_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_export_batch_claims_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT uq_claim_export_batch_claims UNIQUE (claim_export_batch_id, claim_id)
);

CREATE TABLE claim_status_history (
    claim_status_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    old_status_id UUID,
    new_status_id UUID NOT NULL,
    changed_by UUID NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    CONSTRAINT fk_claim_status_history_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_status_history_old_status FOREIGN KEY (old_status_id) REFERENCES claim_statuses (claim_status_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_status_history_new_status FOREIGN KEY (new_status_id) REFERENCES claim_statuses (claim_status_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_status_history_changed_by FOREIGN KEY (changed_by) REFERENCES users (user_id) ON DELETE SET NULL
);

CREATE TABLE claim_assignment_history (
    claim_assignment_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    old_assigned_to UUID,
    new_assigned_to UUID,
    assigned_by UUID NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    CONSTRAINT fk_claim_assignment_history_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_assignment_history_old_assignee FOREIGN KEY (old_assigned_to) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_assignment_history_new_assignee FOREIGN KEY (new_assigned_to) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_assignment_history_assigned_by FOREIGN KEY (assigned_by) REFERENCES users (user_id) ON DELETE SET NULL
);

CREATE TABLE claim_edit_history (
    claim_edit_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    edited_by UUID NOT NULL,
    edited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    field_name VARCHAR(128) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    reason TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    CONSTRAINT fk_claim_edit_history_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_edit_history_edited_by FOREIGN KEY (edited_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_claim_edit_history_field_name_not_empty CHECK (field_name <> '')
);

CREATE TABLE claim_export_history (
    claim_export_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    claim_export_batch_id UUID,
    old_status_id UUID,
    new_status_id UUID NOT NULL,
    exported_by UUID NOT NULL,
    exported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    CONSTRAINT fk_claim_export_history_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_export_history_batch FOREIGN KEY (claim_export_batch_id) REFERENCES claim_export_batches (claim_export_batch_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_export_history_old_status FOREIGN KEY (old_status_id) REFERENCES claim_statuses (claim_status_id) ON DELETE SET NULL,
    CONSTRAINT fk_claim_export_history_new_status FOREIGN KEY (new_status_id) REFERENCES claim_statuses (claim_status_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_export_history_exported_by FOREIGN KEY (exported_by) REFERENCES users (user_id) ON DELETE SET NULL
);

CREATE TABLE claim_reports (
    claim_report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL,
    claim_report_type_id UUID NOT NULL,
    generated_by UUID,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    title VARCHAR(255),
    summary TEXT,
    report_data JSONB NOT NULL DEFAULT '{}'::JSONB,
    file_name VARCHAR(255),
    file_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_claim_reports_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_reports_type FOREIGN KEY (claim_report_type_id) REFERENCES claim_report_types (claim_report_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_claim_reports_generated_by FOREIGN KEY (generated_by) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_claim_reports_title_or_file_name CHECK (title <> '' OR file_name IS NOT NULL)
);

CREATE TABLE audit_log_events (
    audit_log_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL,
    user_id UUID,
    action VARCHAR(128) NOT NULL,
    target_type VARCHAR(64),
    target_id UUID,
    claim_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_audit_log_events_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals (hospital_id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_log_events_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_log_events_claim FOREIGN KEY (claim_id) REFERENCES claims (claim_id) ON DELETE SET NULL,
    CONSTRAINT chk_audit_log_events_action_not_empty CHECK (action <> '')
);

-- user indexes already declared earlier; removed duplicates

CREATE INDEX idx_patients_hospital_id ON patients (hospital_id);
CREATE INDEX idx_patients_full_name_trgm ON patients USING gin (lower(full_name) gin_trgm_ops);
CREATE INDEX idx_patients_external_id ON patients (hospital_id, external_patient_id);
CREATE INDEX idx_patients_mrn ON patients (hospital_id, medical_record_number);

CREATE INDEX idx_drugs_name_trgm ON drugs USING gin (lower(name) gin_trgm_ops);
CREATE INDEX idx_drugs_generic_name_trgm ON drugs USING gin (lower(generic_name) gin_trgm_ops);
CREATE INDEX idx_drugs_rxnorm_code ON drugs (rxnorm_code);
CREATE INDEX idx_drugs_deleted_at ON drugs (deleted_at);

CREATE INDEX idx_formulary_entries_hospital_drug ON formulary_entries (hospital_id, drug_id);
CREATE INDEX idx_formulary_entries_active ON formulary_entries (hospital_id, drug_id) WHERE is_active = TRUE AND deleted_at IS NULL;

CREATE INDEX idx_icd_codes_code ON icd_codes (code);
CREATE INDEX idx_icd_codes_description_trgm ON icd_codes USING gin (lower(description) gin_trgm_ops);
CREATE INDEX idx_icd_codes_deleted_at ON icd_codes (deleted_at);

CREATE INDEX idx_icd_code_keywords_icd ON icd_code_keywords (icd_code_id);
CREATE INDEX idx_icd_code_keywords_keyword_lower ON icd_code_keywords (lower(keyword_text));
CREATE INDEX idx_icd_code_keywords_search ON icd_code_keywords USING gin (lower(keyword_text) gin_trgm_ops);
CREATE INDEX idx_icd_code_keywords_active ON icd_code_keywords (icd_code_id, keyword_text) WHERE is_active = TRUE AND deleted_at IS NULL;

CREATE INDEX idx_gdrg_tariffs_hospital_icd ON gdrg_tariffs (hospital_id, icd_code_id, version);
CREATE INDEX idx_gdrg_tariffs_effective ON gdrg_tariffs (effective_from, effective_to);
CREATE INDEX idx_addon_types_hospital_code ON addon_types (hospital_id, code, version);
CREATE INDEX idx_penalty_rules_hospital_code ON penalty_rules (hospital_id, code, version);
CREATE INDEX idx_audit_rules_hospital_rule_key ON audit_rules (hospital_id, rule_key, version);
CREATE INDEX idx_audit_rules_diagnosis_keyword ON audit_rules (lower(applies_to_diagnosis_keyword));

CREATE INDEX idx_interactions_hospital_code ON interactions (hospital_id, interaction_code, version);
CREATE INDEX idx_interactions_severity ON interactions (severity);
CREATE INDEX idx_interaction_subjects_interaction_id ON interaction_subjects (interaction_id);
CREATE INDEX idx_interaction_subjects_drug_id ON interaction_subjects (drug_id);
CREATE INDEX idx_interaction_subjects_condition_icd_code_id ON interaction_subjects (condition_icd_code_id);

CREATE INDEX idx_claim_export_batches_hospital_id ON claim_export_batches (hospital_id);
CREATE INDEX idx_claim_export_batches_status_id ON claim_export_batches (export_batch_status_id);
CREATE INDEX idx_claim_export_batches_created_by ON claim_export_batches (created_by);

CREATE INDEX idx_claims_hospital_status_created_at ON claims (hospital_id, current_status_id, created_at DESC);
CREATE INDEX idx_claims_hospital_patient ON claims (hospital_id, patient_id);
CREATE INDEX idx_claims_assigned_to ON claims (assigned_to);
CREATE INDEX idx_claims_discharge_date ON claims (discharge_date);
CREATE INDEX idx_claims_admission_date ON claims (admission_date);
CREATE INDEX idx_claims_deleted_at ON claims (deleted_at);

CREATE INDEX idx_claim_diagnoses_claim_id ON claim_diagnoses (claim_id);
CREATE INDEX idx_claim_diagnoses_icd_role ON claim_diagnoses (icd_code_id, diagnosis_role_id);
CREATE INDEX idx_claim_diagnoses_role ON claim_diagnoses (diagnosis_role_id);

CREATE INDEX idx_claim_icd_mappings_claim_id ON claim_icd_mappings (claim_id);
CREATE INDEX idx_claim_icd_mappings_icd_code_id ON claim_icd_mappings (icd_code_id);
CREATE INDEX idx_claim_icd_mappings_keyword_id ON claim_icd_mappings (icd_code_keyword_id);

CREATE INDEX idx_claim_medications_claim_id ON claim_medications (claim_id);
CREATE INDEX idx_claim_medications_drug_id ON claim_medications (drug_id);
CREATE INDEX idx_claim_medications_raw_name_trgm ON claim_medications USING gin (lower(raw_name) gin_trgm_ops);

CREATE INDEX idx_claim_charge_lines_claim_id ON claim_charge_lines (claim_id);
CREATE INDEX idx_claim_charge_lines_type_id ON claim_charge_lines (claim_charge_line_type_id);

CREATE INDEX idx_claim_audit_flags_claim_id ON claim_audit_flags (claim_id);
CREATE INDEX idx_claim_audit_flags_audit_level_id ON claim_audit_flags (audit_level_id);
CREATE INDEX idx_claim_audit_flags_rule_id ON claim_audit_flags (audit_rule_id);

CREATE INDEX idx_claim_penalties_claim_id ON claim_penalties (claim_id);
CREATE INDEX idx_claim_penalties_rule_id ON claim_penalties (penalty_rule_id);

CREATE INDEX idx_claim_export_batch_claims_batch_id ON claim_export_batch_claims (claim_export_batch_id);
CREATE INDEX idx_claim_export_batch_claims_claim_id ON claim_export_batch_claims (claim_id);

CREATE INDEX idx_claim_status_history_claim_id ON claim_status_history (claim_id);
CREATE INDEX idx_claim_status_history_changed_at ON claim_status_history (claim_id, changed_at DESC);

CREATE INDEX idx_claim_assignment_history_claim_id ON claim_assignment_history (claim_id);
CREATE INDEX idx_claim_assignment_history_new_assigned_to ON claim_assignment_history (new_assigned_to);

CREATE INDEX idx_claim_edit_history_claim_id ON claim_edit_history (claim_id);
CREATE INDEX idx_claim_edit_history_edited_at ON claim_edit_history (claim_id, edited_at DESC);

CREATE INDEX idx_claim_export_history_claim_id ON claim_export_history (claim_id);
CREATE INDEX idx_claim_export_history_batch_id ON claim_export_history (claim_export_batch_id);

CREATE INDEX idx_claim_reports_claim_id ON claim_reports (claim_id);
CREATE INDEX idx_claim_reports_type_id ON claim_reports (claim_report_type_id);

CREATE INDEX idx_audit_log_events_hospital_id ON audit_log_events (hospital_id);
CREATE INDEX idx_audit_log_events_user_id ON audit_log_events (user_id);
CREATE INDEX idx_audit_log_events_claim_id ON audit_log_events (claim_id);
CREATE INDEX idx_audit_log_events_action ON audit_log_events (action);
CREATE INDEX idx_audit_log_events_metadata_gin ON audit_log_events USING gin (metadata);
