def generate_discharge(data):
    diagnosis = data.get('diagnosis', 'Unspecified')
    meds = ', '.join(data.get('meds', [])) if data.get('meds') else 'None'
    return f"DIAGNOSIS: {diagnosis}\nTREATMENT GIVEN: {meds}\nADVICE: Complete all medications. Return to clinic in 1 week or if condition worsens."
