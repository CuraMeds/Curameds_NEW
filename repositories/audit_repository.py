from database.db import transaction

class AuditRepository:
    @staticmethod
    def load_rules():
        try:
            with transaction() as cur:
                cur.execute("SELECT a.audit_rule_id, a.rule_key, a.name, a.default_fix, l.code as level_code FROM audit_rules a JOIN audit_levels l ON a.audit_level_id = l.audit_level_id WHERE a.is_active = TRUE")
                rows = cur.fetchall()
                rules = []
                for r in rows:
                    rules.append({'audit_rule_id': r[0], 'rule_key': r[1], 'name': r[2], 'default_fix': r[3], 'level': r[4]})
                return rules
        except Exception:
            return None
