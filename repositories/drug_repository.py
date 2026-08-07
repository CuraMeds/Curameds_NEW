from database.db import transaction

class DrugRepository:
    @staticmethod
    def load_formulary(hospital_id=None):
        try:
            with transaction() as cur:
                if hospital_id:
                    cur.execute("SELECT d.name FROM formulary_entries f JOIN drugs d ON f.drug_id = d.drug_id WHERE f.hospital_id = %s AND f.is_active = TRUE", (hospital_id,))
                else:
                    cur.execute("SELECT name FROM drugs WHERE is_active = TRUE")
                rows = cur.fetchall()
                return [r[0] for r in rows]
        except Exception:
            return None

    @staticmethod
    def find_drug_by_name(name):
        with transaction() as cur:
            cur.execute("SELECT drug_id, name, generic_name, brand_name FROM drugs WHERE lower(name) = lower(%s) LIMIT 1", (name,))
            row = cur.fetchone()
            if not row:
                return None
            return {'drug_id': row[0], 'name': row[1], 'generic_name': row[2], 'brand_name': row[3]}
