from database.db import transaction

class PenaltyRepository:
    @staticmethod
    def load_penalties():
        try:
            with transaction() as cur:
                cur.execute("SELECT code, amount, amount_type FROM penalty_rules WHERE is_active = TRUE")
                rows = cur.fetchall()
                return [{'code': r[0], 'amount': float(r[1]), 'amount_type': r[2]} for r in rows]
        except Exception:
            return None
