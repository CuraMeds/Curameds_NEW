from datetime import datetime

def log_action(user, action, note_hash):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[AUDIT] {timestamp} | User: {user} | Action: {action} | NoteHash: {note_hash}")
