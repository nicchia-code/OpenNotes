---
status: resolved
resolution: fix-code
refs:
  - sync-run/Running
proposal: null
task: sgc92gr1
origin: vg7f9a0g
critical: false
option: 1
note: null
resolvedBy: gdnc8czu
created: 2026-10-17T17:40:52.748Z
---
# Sync failures have no readable app log

## What happens

Oggi ogni fallimento di un giro e ogni caricamento o download di allegato che fallisce viene scritto solo nei messaggi di debug, che l'utente non può leggere. Il Model e i Requirements chiedono che l'errore con il dettaglio tecnico venga annotato nel **registro dell'app**, ma non dicono dove il registro vive né come l'utente lo consulta: il codice non ha nessun registro dell'app, quindi non c'è un posto dove annotarlo.

## What should happen

Il Model dice che l'errore viene annotato nel registro dell'app e che l'app ne mostra la categoria; i Requirements dicono che ogni errore finisce nel registro con il dettaglio tecnico. Né il Model né i Requirements stabiliscono cos'è il registro: se è persistente tra un avvio e l'altro, dove viene conservato, quanto cresce e chi può leggerlo. Senza questa scelta il lavoro non può essere completato in modo verificabile.

## Fix options

### Registro su file nella cartella documenti dell'app

Ogni errore viene aggiunto con data, categoria e dettaglio tecnico a un file di testo nella cartella documenti dell'app, accanto al database. Il file resta tra un avvio e l'altro e cresce; viene tagliato ai run più recenti per tenerne la dimensione sotto controllo. Costo: un file in più sul dispositivo, ma l'utente può aprirlo e allegarlo a una segnalazione.

### Registro in memoria con le ultime voci

Le ultime voci di errore sono tenute in memoria, in una lista di dimensione fissa, e mostrate nella finestra delle impostazioni del cloud. Nessun file, nessuna scrittura su disco. Costo: il registro si perde alla chiusura dell'app, quindi un errore avvenuto prima del riavvio non è più leggibile.

### Registro su file nel vault

Le voci vengono scritte in un file dentro la cartella del vault, così l'utente le trova dove già trova le sue note. Costo: il vault è pensato per le note; un file di log al suo interno finisce anche nei backup e nelle copie delle note, e l'utente lo vedrebbe tra i file di contenuto.

## Where in the code

lib/core/services/sync_service.dart: _runOnce (catch degli errori di giro), _uploadMissingAttachments, _downloadAttachmentsOfAllNotes; oggi usano debugPrint
