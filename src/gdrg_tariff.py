from repositories.tariff_repository import TariffRepository

GDRG_TARIFF = {
    "B50.9": {"gdrg": "N03A", "name": "Malaria Simple", "base_tariff": 25000, "base_days": 3, "per_extra_day": 4000},
    "B50.0": {"gdrg": "N03B", "name": "Malaria Severe", "base_tariff": 65400, "base_days": 7, "per_extra_day": 5000},
    "O80": {"gdrg": "M01A", "name": "Normal Delivery", "base_tariff": 75000, "base_days": 2, "per_extra_day": 8000},
    "O82": {"gdrg": "M01B", "name": "C-Section", "base_tariff": 180000, "base_days": 5, "per_extra_day": 9000},
    "J18.9": {"gdrg": "R04A", "name": "Pneumonia", "base_tariff": 120500, "base_days": 7, "per_extra_day": 7000},
    "I10": {"gdrg": "C05A", "name": "Hypertension", "base_tariff": 45000, "base_days": 3, "per_extra_day": 4000},
    "E11.9": {"gdrg": "E02A", "name": "Diabetes", "base_tariff": 55000, "base_days": 4, "per_extra_day": 4500},
    "A01.0": {"gdrg": "G01A", "name": "Typhoid", "base_tariff": 80000, "base_days": 7, "per_extra_day": 6000},
}

ADD_ONS = {"blood_transfusion": 25000, "icu": 50000, "dialysis": 40000, "surgery": 30000}
PENALTIES = {"no_lab": 0.30}

def calculate_nhia_amount(icd_code, days=1, addons=[], flags=[], hospital_id=None):
    # Try database-backed tariff first
    db_data = None
    try:
        db_data = TariffRepository.get_latest_by_icd_code(icd_code, hospital_id=hospital_id)
    except Exception:
        db_data = None

    if db_data:
        data = db_data
    else:
        data = GDRG_TARIFF.get(icd_code, {"gdrg": "Z99", "name": "Unclassified", "base_tariff": 50000, "base_days": 3, "per_extra_day": 3000})

    amount = data["base_tariff"]
    breakdown = [f"Base: {data['gdrg']} - {data.get('name','Unknown')} = ₦{int(data['base_tariff']):,}"]

    if days > data.get("base_days", 1):
        extra_days = days - data.get("base_days", 1)
        extra_pay = extra_days * int(data.get("per_extra_day", 0))
        amount += extra_pay
        breakdown.append(f"+ {extra_days} extra days = ₦{extra_pay:,}")

    for addon in addons:
        if addon in ADD_ONS:
            amount += ADD_ONS[addon]
            breakdown.append(f"+ {addon.replace('_',' ').title()} = ₦{ADD_ONS[addon]:,}")

    final_amount = amount
    for f in flags:
        if f.get("level") == "RED" and "lab" in f.get("issue","").lower():
            cut = final_amount * PENALTIES["no_lab"]
            final_amount -= cut
            breakdown.append(f"- 30% No Lab Penalty = -₦{int(cut):,}")

    return {
        "gdrg_code": data.get("gdrg"),
        "gdrg_name": data.get("name"),
        "calculated_amount": int(final_amount),
        "breakdown": "\n".join(breakdown)
    }
