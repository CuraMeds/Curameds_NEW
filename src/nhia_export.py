import pandas as pd
from datetime import datetime
import os

def generate_nhia_excel(processed_claims, hospital_name):
    rows = []
    for claim in processed_claims:
        icd = claim['icd_codes'][0] if claim['icd_codes'] else {"code": "R69", "description": "Unknown"}
        gdrg = claim.get('gdrg', {})
        rows.append({
            "HCP Code": "",
            "Patient ID": f"PT{abs(hash(claim['note'])) % 100000}",
            "Date of Service": datetime.now().strftime("%Y-%m-%d"),
            "ICD-10 Code": icd['code'],
            "ICD-10 Description": icd['description'],
            "G-DRG Code": gdrg.get("gdrg_code", "Z99"),
            "G-DRG Name": gdrg.get("gdrg_name", "Unclassified"),
            "Days on Admission": claim.get("days", 1),
            "Amount Calculated": gdrg.get("calculated_amount", 50000),
            "NHIA Flags": "; ".join([f"{f['level']}: {f['issue']}" for f in claim['nhia_audit']['flags']]),
            "Drugs": ", ".join(claim.get("meds", [])),
            "Status": "Ready for Submission"
        })
    df = pd.DataFrame(rows)
    filename = f"NHIA_Claim_GDRG_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    filepath = os.path.join("exports", filename)
    os.makedirs("exports", exist_ok=True)
    df.to_excel(filepath, index=False)
    return filepath, len(rows)
