---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
proposal: null
task: cwv8yetl
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:05.037Z
---
# Remote note change ignored while a local delete is queued

## What happens

Se il cloud invia una nota che il dispositivo ha eliminata e la cui eliminazione è ancora in coda, la versione del cloud viene scartata e la nota non torna. Alla sincronizzazione successiva l'eliminazione parte e la nota sparisce anche dal cloud, anche se il cloud l'aveva modificata dopo che l'eliminazione era stata fatta.

## What should happen

Il Model dice che la versione del cloud sostituisce la copia locale quando il dispositivo non ha la nota, oppure quando la sua copia non è più recente di quella del cloud; altrimenti non succede nulla. Nella sincronizzazione completa, invece, un'eliminazione in coda viene scartata se il cloud ha modificato la nota dopo che l'eliminazione è entrata in coda, e la nota torna sul dispositivo.

## Fix options

### Confrontare con la data dell'eliminazione in coda

La versione del cloud sostituisce la nota quando è stata modificata dopo che l'eliminazione è entrata in coda, e in quel caso l'eliminazione in coda viene tolta. Altrimenti l'eliminazione resta e viene inviata. Così il canale in tempo reale segue il Model e resta coerente con la regola della sincronizzazione completa. Costo: il confronto con la data della coda va aggiunto sia al canale sia alla sincronizzazione, che oggi invia sempre l'eliminazione.

### Tenere l'eliminazione in coda sempre vincente

La nota eliminata resta eliminata e la copia del cloud viene ignorata, come oggi. Il Model del canale in tempo reale va riscritto, e la regola della sincronizzazione va allineata alla stessa scelta. Nessun cambio di codice nel canale. Costo: una modifica fatta da un altro dispositivo dopo l'eliminazione non torna sul dispositivo.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteNoteChange e applyRemoteNote (controllo dell'eliminazione in coda)
