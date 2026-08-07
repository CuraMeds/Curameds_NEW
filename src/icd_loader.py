import json
import os

ICD_FILE = "data/icd10_master.json"

def load_icd_master():
    with open(ICD_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    icd_keywords = {item["keyword"].lower(): {"code": item["code"], "desc": item["desc"]} for item in data}
    return icd_keywords, data

ICD_KEYWORDS, ICD_MASTER = load_icd_master()

NHIA_RULES = {
    "malaria": "Attach RDT/MPS result",
    "typhoid": "Attach Widal/Culture",
    "hypertension": "Document BP reading",
    "diabetes": "Attach RBS/FBS/HbA1c",
    "pneumonia": "Attach CXR",
    "c-section": "Attach surgical note",
    "normal delivery": "Attach partograph",
}
for k in ICD_KEYWORDS.keys():
    if k not in NHIA_RULES:
        NHIA_RULES[k] = "Attach supporting clinical note/lab"

FORMULARY = ["Paracetamol", "Amoxicillin", "Artemether-Lumefantrine", "Ceftriaxone",
             "Nifedipine", "Amlodipine", "Metformin", "Glimepiride", "Insulin", "ORS", "Zinc", "IV Fluids"]

HOSPITAL_NAME = "CuraMeds NHIA Audit - ABUAD"
print(f"✅ Loaded {len(ICD_KEYWORDS)} ICD-10 codes")
