from database.db import transaction, gen_uuid

class ExportRepository:
    @staticmethod
    def create_export_batch(hospital_id, created_by, name, export_status_id):
        with transaction() as cur:
            bid = gen_uuid()
            cur.execute(
                "INSERT INTO claim_export_batches (claim_export_batch_id, hospital_id, created_by, name, export_batch_status_id, claim_count, total_amount, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,0,0,now(),now())",
                (bid, hospital_id, created_by, name, export_status_id)
            )
            return bid

    @staticmethod
    def add_claims_to_batch(batch_id, claim_ids):
        with transaction() as cur:
            for cid in claim_ids:
                eid = gen_uuid()
                cur.execute("INSERT INTO claim_export_batch_claims (claim_export_batch_claim_id, claim_export_batch_id, claim_id, added_at) VALUES (%s,%s,%s,now())", (eid, batch_id, cid))
            cur.execute("UPDATE claim_export_batches SET claim_count = claim_count + %s, updated_at = now() WHERE claim_export_batch_id = %s", (len(claim_ids), batch_id))
