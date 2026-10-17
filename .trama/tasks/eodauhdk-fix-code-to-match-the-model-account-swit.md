---
column: done
technical: false
refs:
  - pending-change/Pending/sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
  - requirements/rules#pending-change
drift: null
proposal: null
agent: false
created: 2026-10-17T19:25:11.961Z
finished: 2026-10-17T19:49:44.265Z
---
# Fix code to match the Model: Account switch keeps queued deletes of notes deleted for good before the switch

Quando l'utente connesso cambia, le cancellazioni in coda delle note già sincronizzate dal precedente account che l'utente aveva eliminato definitivamente prima del cambio devono essere scartate senza invio, come le modifiche in attesa delle note rimosse per il cambio di account. Oggi vengono conservate: il cambio di account tocca solo le note ancora presenti sul dispositivo, quindi la cancellazione di una nota già eliminata resta in coda, viene inviata al nuovo account e da lì viene rifiutata e messa da parte. Il nuovo account non deve ricevere cancellazioni di note che non gli appartengono. Le cancellazioni di note mai sincronizzate restano in coda e vengono inviate come prima.
