---
column: done
technical: false
refs:
  - folder/User folder/sync-run.FINISHED
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
drift: m3jlz8ca
proposal: null
agent: false
created: 2026-10-12T18:00:24.492Z
finished: 2026-10-12T18:03:42.089Z
---
# Fix code to match the Model: Folder deleted in the cloud while offline is never removed by a full sync

## What happens

Se una cartella viene eliminata su un altro dispositivo mentre questo è fuori linea, la sincronizzazione completa non la rimuove. La cartella resta visibile qui con le sue note, mentre nel cloud non esiste più. Solo l'eliminazione ricevuta in tempo reale la toglie dal dispositivo; chi era fuori linea in quel momento non la riceve mai.

## What should happen

Il Model della cartella dice che la sincronizzazione completa aggiunge o aggiorna le cartelle scaricate, e che l'eliminazione arriva solo come REMOTE_FOLDER_DELETED dal canale in tempo reale. Non dice cosa succede a una cartella locale, senza modifiche in coda, che il cloud non ha più: il caso è assente. Per le note la regola esiste solo se c'è un salvataggio in coda.

## Chosen option

**Remove folders the cloud no longer has**

Alla sincronizzazione completa, una cartella locale senza modifiche in coda che il cloud non ha più viene eliminata come con REMOTE_FOLDER_DELETED: le sue note passano in Note, senza essere accodate. Le cartelle con una creazione o una rinomina in coda restano. Il Model della cartella e della sincronizzazione va completato con questa regola. Costa una lettura di confronto in più a ogni sincronizzazione.

## Where in the code

lib/core/services/sync_service.dart (syncNow, passo 4: solo upsert delle cartelle remote, nessuna rimozione)
