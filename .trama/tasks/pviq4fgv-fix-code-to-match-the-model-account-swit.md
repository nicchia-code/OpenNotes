---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - pending-change/Pending/sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
drift: null
proposal: null
agent: false
created: 2026-10-17T19:27:56.273Z
finished: 2026-10-17T19:37:06.433Z
---
# Fix code to match the Model: Account switch discards queued deletes of notes purged before the switch

Al cambio di account, le cancellazioni in coda delle note già sincronizzate con il precedente account, che l'utente aveva eliminato definitivamente prima del cambio, vanno scartate senza essere inviate, come le altre modifiche in attesa di quelle note. Oggi la nota non è più sul dispositivo e nessuna regola scarta la sua cancellazione: il nuovo account la invia, il cloud la rifiuta per permessi, e dopo tre giri la cancellazione viene messa da parte e compare tra le non sincronizzate con il solo identificativo della nota. Fatto quando: dopo un cambio di account nessuna cancellazione del precedente account viene inviata, e nessun elemento del precedente account resta in coda o tra le non sincronizzate.
