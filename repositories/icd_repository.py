from database.db import transaction

class ICDRepository:
    @staticmethod
    def load_keyword_map():
        try:
            with transaction() as cur:
                cur.execute("SELECT k.keyword_text, c.code, c.description FROM icd_code_keywords k JOIN icd_codes c ON k.icd_code_id = c.icd_code_id WHERE k.is_active = TRUE AND c.is_active = TRUE")
                rows = cur.fetchall()
                mapping = {r[0].lower(): {'code': r[1], 'desc': r[2]} for r in rows}
                return mapping
        except Exception:
            return None

    @staticmethod
    def get_icd_by_code(code):
        with transaction() as cur:
            cur.execute("SELECT icd_code_id, code, description FROM icd_codes WHERE code = %s LIMIT 1", (code,))
            row = cur.fetchone()
            if not row:
                return None
            return {'icd_code_id': row[0], 'code': row[1], 'description': row[2]}
