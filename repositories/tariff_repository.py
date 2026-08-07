from database.db import transaction

class TariffRepository:
    @staticmethod
    def get_latest_by_icd_code(icd_code, hospital_id=None):
        # Find icd_code_id
        with transaction() as cur:
            cur.execute("SELECT icd_code_id FROM icd_codes WHERE code = %s LIMIT 1", (icd_code,))
            row = cur.fetchone()
            if not row:
                return None
            icd_id = row[0]
            if hospital_id:
                cur.execute("SELECT gdrg_code, gdrg_name, base_tariff, base_days, per_extra_day FROM gdrg_tariffs WHERE icd_code_id = %s AND hospital_id = %s AND is_active = TRUE ORDER BY version DESC LIMIT 1", (icd_id, hospital_id))
                r = cur.fetchone()
            else:
                cur.execute("SELECT gdrg_code, gdrg_name, base_tariff, base_days, per_extra_day FROM gdrg_tariffs WHERE icd_code_id = %s AND is_active = TRUE ORDER BY version DESC LIMIT 1", (icd_id,))
                r = cur.fetchone()
            if not r:
                return None
            return {'gdrg': r[0], 'name': r[1], 'base_tariff': int(r[2]), 'base_days': r[3], 'per_extra_day': int(r[4])}
