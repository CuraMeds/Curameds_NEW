from database.db import transaction, gen_uuid

class HospitalRepository:
    DEFAULT_CODE = 'DEFAULT'

    @staticmethod
    def ensure_default_hospital():
        with transaction() as cur:
            cur.execute("SELECT hospital_id FROM hospitals WHERE code = %s LIMIT 1", (HospitalRepository.DEFAULT_CODE,))
            row = cur.fetchone()
            if row:
                return row[0]
            hid = gen_uuid()
            cur.execute(
                "INSERT INTO hospitals (hospital_id, code, name, timezone, default_currency, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,now(),now())",
                (hid, HospitalRepository.DEFAULT_CODE, 'Default Hospital', 'Africa/Lagos', 'NGN')
            )
            return hid
