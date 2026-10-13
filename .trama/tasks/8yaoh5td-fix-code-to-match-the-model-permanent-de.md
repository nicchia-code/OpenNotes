---
column: done
technical: false
refs:
  - pending-change
  - note/In trash/user.DELETE_NOTE_PERMANENTLY
drift: null
proposal: null
agent: false
created: 2026-10-12T16:48:49.778Z
finished: 2026-10-12T17:09:32.391Z
---
# Fix code to match the Model: Permanent deletion of a never-synced welcome note queues nothing for the cloud

Eliminando definitivamente dal cestino una nota di benvenuto mai sincronizzata, la cancellazione deve entrare nella coda come per ogni altra nota eliminata definitivamente, e la sincronizzazione parte se un utente è connesso. Oggi la nota sparisce dal dispositivo senza che nulla venga accodato: il Model dice che solo i salvataggi di queste note non entrano in coda. I salvataggi di una nota di benvenuto mai sincronizzata restano fuori dalla coda, come oggi.
