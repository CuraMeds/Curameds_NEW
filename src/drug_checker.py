def check_interactions(meds, formulary):
    warnings = []
    meds_lower = [m.lower() for m in meds]
    if "ceftriaxone" in meds_lower and "calcium" in meds_lower:
        warnings.append("WARNING: Ceftriaxone + Calcium - Risk of precipitation")
    if "metformin" in meds_lower and "insulin" in meds_lower:
        warnings.append("WARNING: Metformin + Insulin - Risk of Hypoglycemia")

    on_formulary = [m for m in meds if m in formulary]
    off_formulary = [m for m in meds if m not in formulary]

    return {
        "status": "OK" if not warnings else "WARNING",
        "warnings": warnings,
        "on_formulary": on_formulary,
        "off_formulary": off_formulary
    }
