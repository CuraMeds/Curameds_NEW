import json
import os

ICD_FILE = "data/icd10_master.json"

def load_icd_master():
    with open(ICD_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    icd_keywords = {item["keyword"].lower(): {"code": item["code"], "desc": item["desc"]} for item in data}
    return icd_keywords, data

from repositories.icd_repository import ICDRepository
from repositories.audit_repository import AuditRepository
from repositories.drug_repository import DrugRepository

# Try loading from DB; fall back to file-based loader for local dev
_map = ICDRepository.load_keyword_map()
if _map is None:
    ICD_KEYWORDS, ICD_MASTER = load_icd_master()
else:
    ICD_KEYWORDS = _map
    ICD_MASTER = []

# NHIA rules loaded from DB audit rules if available
_r = AuditRepository.load_rules()
if _r:
    NHIA_RULES = {r['rule_key']: r['default_fix'] for r in _r}
else:
    NHIA_RULES = {k: 'Attach supporting clinical note/lab' for k in ICD_KEYWORDS.keys()}

# Formulary from DB or fallback
_f = DrugRepository.load_formulary()
if _f:
    FORMULARY = _f
else:
    FORMULARY = ["Paracetamol", "Amoxicillin", "Artemether-Lumefantrine", "Ceftriaxone",
                 "Nifedipine", "Amlodipine", "Metformin", "Glimepiride", "Insulin", "ORS", "Zinc", "IV Fluids"]

HOSPITAL_NAME = "CuraMeds NHIA Audit - ABUAD"
print(f"✅ Loaded {len(ICD_KEYWORDS)} ICD-10 codes (source: DB or local file)")
