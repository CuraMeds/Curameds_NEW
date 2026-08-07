def run_nhia_audit(note, diagnosis, meds, nhia_rules):
    flags = []
    note_lower = note.lower()
    revenue_at_risk = 0
    diagnosis_lower = diagnosis.lower()

    if "malaria" in diagnosis_lower:
        if "rdt" not in note_lower and "microscopy" not in note_lower and "mp" not in note_lower:
            flags.append({"level": "RED", "issue": "Missing lab evidence for Malaria", "fix": nhia_rules.get("malaria")})
            revenue_at_risk += 15000

    if "typhoid" in diagnosis_lower:
        if "widal" not in note_lower and "culture" not in note_lower:
            flags.append({"level": "RED", "issue": "Missing lab evidence for Typhoid", "fix": nhia_rules.get("typhoid")})
            revenue_at_risk += 15000

    if "bp" not in note_lower:
        flags.append({"level": "YELLOW", "issue": "Blood Pressure not documented", "fix": "Add BP e.g BP 120/80"})

    estimated_payout = 50000 - revenue_at_risk
    return {"flags": flags, "estimated_payout": f"₦{max(estimated_payout, 0):,}"}
