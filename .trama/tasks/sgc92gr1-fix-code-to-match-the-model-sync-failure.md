---
column: done
technical: false
refs:
  - sync-run/Running
drift: hoovlhvs
proposal: null
agent: false
created: 2026-10-17T18:07:16.433Z
finished: 2026-10-17T18:51:37.796Z
---
# Fix code to match the Model: Sync failures have no readable app log

## What happens

Oggi ogni fallimento di un giro e ogni caricamento o download di allegato che fallisce viene scritto solo nei messaggi di debug, che l'utente non può leggere. Il Model e i Requirements chiedono che l'errore con il dettaglio tecnico venga annotato nel **registro dell'app**, ma non dicono dove il registro vive né come l'utente lo consulta: il codice non ha nessun registro dell'app, quindi non c'è un posto dove annotarlo.

## What should happen

Il Model dice che l'errore viene annotato nel registro dell'app e che l'app ne mostra la categoria; i Requirements dicono che ogni errore finisce nel registro con il dettaglio tecnico. Né il Model né i Requirements stabiliscono cos'è il registro: se è persistente tra un avvio e l'altro, dove viene conservato, quanto cresce e chi può leggerlo. Senza questa scelta il lavoro non può essere completato in modo verificabile.

## Chosen option

**Registro su file nella cartella documenti dell'app**

Ogni errore viene aggiunto con data, categoria e dettaglio tecnico a un file di testo nella cartella documenti dell'app, accanto al database. Il file resta tra un avvio e l'altro e cresce; viene tagliato ai run più recenti per tenerne la dimensione sotto controllo. Costo: un file in più sul dispositivo, ma l'utente può aprirlo e allegarlo a una segnalazione.

## Where in the code

lib/core/services/sync_service.dart: _runOnce (catch degli errori di giro), _uploadMissingAttachments, _downloadAttachmentsOfAllNotes; oggi usano debugPrint
