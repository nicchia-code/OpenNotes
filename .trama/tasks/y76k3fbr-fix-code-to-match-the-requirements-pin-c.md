---
column: done
technical: false
refs:
  - note-access/Protected
  - note-access/Protected/user.REMOVE_NOTE_LOCK
  - note-access/Unprotected/user.LOCK_NOTE
  - requirements/rules#note-access
drift: null
proposal: null
agent: false
created: 2026-10-17T19:21:59.173Z
finished: 2026-10-17T19:39:43.645Z
---
# Fix code to match the Requirements: PIN checks use the lock state the user saw, not the stored note

Ogni azione su una nota protetta chiede il PIN in base allo stato di protezione che la nota ha al momento dell'azione, letto dalla memoria locale e non dalla copia mostrata nel menu o nell'editor quando il menu è stato aperto. Se nel frattempo il cloud ha protetto la nota, duplicare, condividere, esportare in Markdown, eliminare definitivamente o togliere il lucchetto chiedono il PIN corretto prima di agire. Il lucchetto non viene mai tolto senza PIN: mettere o togliere il lucchetto decide l'azione dallo stato memorizzato, non dalla copia vista dall'utente. Se la nota non è più protetta, l'azione non chiede il PIN.
