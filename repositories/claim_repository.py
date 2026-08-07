from database.db import transaction, gen_uuid

class ClaimRepository:
    @staticmethod
    def create_claim(claim_data, created_by=None):
        # claim_data expected keys: hospital_id, patient_id, claim_reference, current_status_id,
        # admission_date, discharge_date, days_on_admission, primary_icd_code_id, raw_note, note_hash,
        # extracted_diagnosis, discharge_summary, total_amount, estimated_payout, nhia_flags_count, tariff_breakdown, currency_code, source_system, source_reference
        with transaction() as cur:
            claim_id = gen_uuid()
            cur.execute(
                "INSERT INTO claims (claim_id, hospital_id, patient_id, claim_reference, current_status_id, created_by, assigned_to, assigned_at, admission_date, discharge_date, days_on_admission, primary_icd_code_id, raw_note, note_hash, extracted_diagnosis, discharge_summary, total_amount, estimated_payout, nhia_flags_count, tariff_breakdown, currency_code, source_system, source_reference, is_active, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,NULL,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,TRUE,now(),now())",
                (
                    claim_id,
                    claim_data.get('hospital_id'),
                    claim_data.get('patient_id'),
                    claim_data.get('claim_reference'),
                    claim_data.get('current_status_id'),
                    created_by,
                    claim_data.get('assigned_to'),
                    claim_data.get('admission_date'),
                    claim_data.get('discharge_date'),
                    claim_data.get('days_on_admission',1),
                    claim_data.get('primary_icd_code_id'),
                    claim_data.get('raw_note'),
                    claim_data.get('note_hash'),
                    claim_data.get('extracted_diagnosis'),
                    claim_data.get('discharge_summary'),
                    claim_data.get('total_amount'),
                    claim_data.get('estimated_payout'),
                    claim_data.get('nhia_flags_count',0),
                    claim_data.get('tariff_breakdown'),
                    claim_data.get('currency_code','NGN'),
                    claim_data.get('source_system'),
                    claim_data.get('source_reference')
                )
            )
            return claim_id

    @staticmethod
    def insert_diagnoses(claim_id, diagnoses):
        with transaction() as cur:
            for d in diagnoses:
                cdid = gen_uuid()
                cur.execute(
                    "INSERT INTO claim_diagnoses (claim_diagnosis_id, claim_id, diagnosis_role_id, icd_code_id, diagnosis_text, rank, confidence_score, source, normalized, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,now(),now())",
                    (
                        cdid,
                        claim_id,
                        d.get('diagnosis_role_id'),
                        d.get('icd_code_id'),
                        d.get('diagnosis_text'),
                        d.get('rank',1),
                        d.get('confidence_score'),
                        d.get('source'),
                        d.get('normalized',False)
                    )
                )

    @staticmethod
    def insert_medications(claim_id, meds):
        with transaction() as cur:
            for m in meds:
                mid = gen_uuid()
                cur.execute(
                    "INSERT INTO claim_medications (claim_medication_id, claim_id, drug_id, formulary_entry_id, raw_name, normalized_name, generic_name, brand_name, strength, dosage, frequency, route, normalized, confidence_score, source, is_on_formulary, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,now(),now())",
                    (
                        mid,
                        claim_id,
                        m.get('drug_id'),
                        m.get('formulary_entry_id'),
                        m.get('raw_name'),
                        m.get('normalized_name'),
                        m.get('generic_name'),
                        m.get('brand_name'),
                        m.get('strength'),
                        m.get('dosage'),
                        m.get('frequency'),
                        m.get('route'),
                        m.get('normalized', False),
                        m.get('confidence_score'),
                        m.get('source'),
                        m.get('is_on_formulary', False)
                    )
                )

    @staticmethod
    def insert_icd_mappings(claim_id, mappings):
        with transaction() as cur:
            for m in mappings:
                mid = gen_uuid()
                cur.execute(
                    "INSERT INTO claim_icd_mappings (claim_icd_mapping_id, claim_id, icd_code_id, icd_code_keyword_id, keyword_text, is_primary, source, confidence_score, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,now(),now())",
                    (
                        mid,
                        claim_id,
                        m.get('icd_code_id'),
                        m.get('icd_code_keyword_id'),
                        m.get('keyword_text'),
                        m.get('is_primary', False),
                        m.get('source'),
                        m.get('confidence_score')
                    )
                )

    @staticmethod
    def insert_audit_flags(claim_id, flags):
        with transaction() as cur:
            for f in flags:
                fid = gen_uuid()
                cur.execute(
                    "INSERT INTO claim_audit_flags (claim_audit_flag_id, claim_id, audit_rule_id, audit_level_id, issue, fix, revenue_at_risk, penalty_amount, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,now(),now())",
                    (
                        fid,
                        claim_id,
                        f.get('audit_rule_id'),
                        f.get('audit_level_id'),
                        f.get('issue'),
                        f.get('fix'),
                        f.get('revenue_at_risk',0),
                        f.get('penalty_amount',0)
                    )
                )

    @staticmethod
    def insert_report(claim_id, report):
        with transaction() as cur:
            rid = gen_uuid()
            cur.execute(
                "INSERT INTO claim_reports (claim_report_id, claim_id, claim_report_type_id, generated_by, generated_at, title, summary, report_data, file_name, file_path, created_at, updated_at) VALUES (%s,%s,%s,%s,now(),%s,%s,%s,%s,%s,now(),now())",
                (
                    rid,
                    claim_id,
                    report.get('claim_report_type_id'),
                    report.get('generated_by'),
                    report.get('title'),
                    report.get('summary'),
                    report.get('report_data'),
                    report.get('file_name'),
                    report.get('file_path')
                )
            )
            return rid
