---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - pending-change/Queued
  - requirements/rules#cloud-sync
drift: mzj6nlf1
proposal: null
agent: false
created: 2026-10-12T18:00:24.507Z
finished: 2026-10-12T18:07:04.485Z
---
# Fix code to match the Model: Salvataggio già in coda di una nota che prende un titolo di benvenuto: il Model dice che viene inviato

## What happens

Una nota mai sincronizzata, salvata con un titolo di benvenuto dopo un salvataggio già in coda (per esempio quando nessun utente era connesso), non invia quel salvataggio: alla sincronizzazione la nota viene eliminata dal dispositivo se il cloud ha già delle note, altrimenti viene inviata con il testo attuale.

## What should happen

Il Model della coda e della sincronizzazione dice che ogni salvataggio in coda viene inviato intero, senza eccezioni per il titolo di benvenuto. Il Requirement dice che una nota di benvenuto mai sincronizzata viene eliminata invece che inviata quando il cloud ha note, e la decisione risolta con hq9t8uit (i6nq1132) chiedeva che il Model dicesse che il salvataggio in coda non viene inviato: questa frase non è mai entrata nel Model della coda.

## Chosen option

**Scrivere lo scarto nel Model**

Il Model della coda e della sincronizzazione aggiunge che un salvataggio in coda di una nota mai sincronizzata con titolo di benvenuto viene tolto senza essere inviato, e che la decisione passa alla sincronizzazione. Il codice resta com'è. Costo: due frasi nel Model.

## Where in the code

lib/core/services/sync_service.dart: syncNow, invio della coda (note, ramo upsert con titolo di benvenuto)
