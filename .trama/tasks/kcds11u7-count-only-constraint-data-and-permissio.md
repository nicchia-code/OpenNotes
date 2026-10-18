---
column: done
technical: false
refs:
  - sync-run.CHANGE_REJECTED
drift: null
proposal: null
agent: false
created: 2026-10-18T19:47:45.310Z
finished: 2026-10-18T19:50:23.296Z
---
# Count only constraint, data and permission database errors as refusals

Il Model (sync-run, evento CHANGE_REJECTED) dice che un rifiuto è un cambiamento in coda che il cloud rifiuta perché non valido o non permesso, non un errore di rete, un tempo scaduto o un conflitto. Il Requirement rules#sync-run dice: rifiuto è una risposta 4xx diversa da 401, 408 e 429, oppure un errore del database per vincolo, dato non valido o permesso; un rifiuto non fa fallire il giro.

Il codice in lib/core/services/sync_service.dart (isCloudRejection) conta come rifiuto ogni codice SQLSTATE tranne le classi 08, 53, 57, 58, XX e i codici PGRST. Così un errore transitorio come una deadlock o una serializzazione fallita (classe 40), un blocco non disponibile (55) o un limite del programma (54) viene contato come rifiuto e, al terzo rifiuto di fila, il cambiamento viene messo da parte.

Da fare: contare come rifiuto solo gli errori del database per vincolo (classe 23), dato non valido (classe 22) e permesso (classe 42), e i codici di risposta 4xx del Requirement. Ogni altro errore del database è un errore imprevisto: il cambiamento resta in coda senza essere contato e il giro fallisce secondo le regole di FAILED.

Fatto quando: un errore transitorio del database lascia il cambiamento in coda, non lo conta e fa fallire il giro come errore imprevisto; un vincolo violato, un dato non valido o un permesso negato lo contano come rifiuto senza far fallire il giro.
