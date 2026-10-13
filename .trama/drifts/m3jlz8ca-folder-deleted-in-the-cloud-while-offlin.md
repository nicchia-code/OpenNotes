---
status: resolved
resolution: fix-code
refs:
  - folder/User folder/sync-run.FINISHED
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
proposal: null
task: c2noyss4
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:52:24.779Z
---
# Folder deleted in the cloud while offline is never removed by a full sync

## What happens

Se una cartella viene eliminata su un altro dispositivo mentre questo è fuori linea, la sincronizzazione completa non la rimuove. La cartella resta visibile qui con le sue note, mentre nel cloud non esiste più. Solo l'eliminazione ricevuta in tempo reale la toglie dal dispositivo; chi era fuori linea in quel momento non la riceve mai.

## What should happen

Il Model della cartella dice che la sincronizzazione completa aggiunge o aggiorna le cartelle scaricate, e che l'eliminazione arriva solo come REMOTE_FOLDER_DELETED dal canale in tempo reale. Non dice cosa succede a una cartella locale, senza modifiche in coda, che il cloud non ha più: il caso è assente. Per le note la regola esiste solo se c'è un salvataggio in coda.

## Fix options

### Remove folders the cloud no longer has

Alla sincronizzazione completa, una cartella locale senza modifiche in coda che il cloud non ha più viene eliminata come con REMOTE_FOLDER_DELETED: le sue note passano in Note, senza essere accodate. Le cartelle con una creazione o una rinomina in coda restano. Il Model della cartella e della sincronizzazione va completato con questa regola. Costa una lettura di confronto in più a ogni sincronizzazione.

### Keep the folder until the user deletes it

La cartella resta sul dispositivo finché l'utente non la elimina, come oggi. Il Model va completato dicendo che le eliminazioni fatte mentre il dispositivo è fuori linea non arrivano. Nessun costo nel codice, ma l'utente può continuare a usare una cartella che sugli altri dispositivi non esiste più.

## Where in the code

lib/core/services/sync_service.dart (syncNow, passo 4: solo upsert delle cartelle remote, nessuna rimozione)
