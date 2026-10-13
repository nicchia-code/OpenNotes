---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
drift: rzj1mn5k
proposal: null
agent: false
created: 2026-10-13T05:23:24.926Z
finished: 2026-10-13T05:25:02.042Z
---
# Fix code to match the Model: Remote note change ignored while a local delete is queued

## What happens

Se il cloud invia una nota che il dispositivo ha eliminata e la cui eliminazione è ancora in coda, la versione del cloud viene scartata e la nota non torna. Alla sincronizzazione successiva l'eliminazione parte e la nota sparisce anche dal cloud, anche se il cloud l'aveva modificata dopo che l'eliminazione era stata fatta.

## What should happen

Il Model dice che la versione del cloud sostituisce la copia locale quando il dispositivo non ha la nota, oppure quando la sua copia non è più recente di quella del cloud; altrimenti non succede nulla. Nella sincronizzazione completa, invece, un'eliminazione in coda viene scartata se il cloud ha modificato la nota dopo che l'eliminazione è entrata in coda, e la nota torna sul dispositivo.

## Chosen option

**Confrontare con la data dell'eliminazione in coda**

La versione del cloud sostituisce la nota quando è stata modificata dopo che l'eliminazione è entrata in coda, e in quel caso l'eliminazione in coda viene tolta. Altrimenti l'eliminazione resta e viene inviata. Così il canale in tempo reale segue il Model e resta coerente con la regola della sincronizzazione completa. Costo: il confronto con la data della coda va aggiunto sia al canale sia alla sincronizzazione, che oggi invia sempre l'eliminazione.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteNoteChange e applyRemoteNote (controllo dell'eliminazione in coda)
