from fastapi import FastAPI, Depends, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import uuid, os

from src.icd_loader import ICD_KEYWORDS, NHIA_RULES, FORMULARY, HOSPITAL_NAME
from src.nhia_audit import run_nhia_audit
from src.discharge_templates import generate_discharge
from src.keyword_mapper import keyword_search_icd10
from src.drug_checker import check_interactions
from src.audit import log_action
from src.auth import fake_login
from src.nhia_export import generate_nhia_excel
from src.gdrg_tariff import calculate_nhia_amount

app = FastAPI(title=f"CuraMeds - {HOSPITAL_NAME}")
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")
CLAIMS_BATCH = []

class NoteIn(BaseModel):
    note: str
    days: int = 1
    addons: list = []
    user_id: str = "dr_ade"

@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse("index.html", {
        "request": request,
        "hospital_name": HOSPITAL_NAME,
        "total_codes": len(ICD_KEYWORDS)
    })

@app.post("/process")
def process_note(data: NoteIn, user = Depends(fake_login)):
    note = data.note
    diagnosis = extract_diagnosis(note)
    meds = extract_meds(note)
    icd_codes = keyword_search_icd10(note, ICD_KEYWORDS)
    audit_flags = run_nhia_audit(note, diagnosis, meds, NHIA_RULES)
    safety = check_interactions(meds, FORMULARY)
    discharge = generate_discharge({"diagnosis": diagnosis, "meds": meds, "note": note})
    main_icd = icd_codes[0]['code']
    gdrg_calc = calculate_nhia_amount(main_icd, days=data.days, addons=data.addons, flags=audit_flags['flags'])

    result = {
        "id": str(uuid.uuid4()),
        "note": note,
        "diagnosis": diagnosis,
        "meds": meds,
        "days": data.days,
        "icd_codes": icd_codes,
        "gdrg": gdrg_calc,
        "nhia_audit": audit_flags,
        "safety": safety,
        "discharge": discharge
    }
    CLAIMS_BATCH.append(result)
    log_action(user["id"], action="processed_note", note_hash=hash(note))
    return result

@app.get("/export")
def export_claims():
    if not CLAIMS_BATCH:
        return {"error": "No claims in batch"}
    filepath, count = generate_nhia_excel(CLAIMS_BATCH, HOSPITAL_NAME)
    CLAIMS_BATCH.clear()
    return FileResponse(filepath, filename=os.path.basename(filepath))

def extract_diagnosis(note):
    note_lower = note.lower()
    for keyword in ICD_KEYWORDS.keys():
        if keyword in note_lower:
            return keyword.title()
    return "Unspecified"

def extract_meds(note):
    note_lower = note.lower()
    return [m for m in FORMULARY if m.lower() in note_lower]

if __name__ == "__main__":
    import uvicorn
    print(f"Running CuraMeds with {len(ICD_KEYWORDS)} ICD-10 codes")
    uvicorn.run(app, host="0.0.0.0", port=8000)
