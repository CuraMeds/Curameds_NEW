def keyword_search_icd10(note, icd_keywords):
    results = []
    note_lower = note.lower()
    for keyword, data in icd_keywords.items():
        if keyword in note_lower:
            results.append({"code": data["code"], "description": data["desc"], "keyword": keyword})
    if not results:
        results.append({"code": "R69", "description": "Unknown and unspecified causes of morbidity", "keyword": "unknown"})
    # remove duplicates
    unique = {v['code']: v for v in results}.values()
    return list(unique)[:5]
