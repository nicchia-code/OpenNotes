---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
proposal: null
task: shl16nf0
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:48:44.247Z
---
# Errore di scrittura del file Markdown non descritto nel Model

## What happens

Se la scrittura del file fallisce dopo che l'utente ha scelto la posizione (cartella di sola lettura, disco pieno, percorso non raggiungibile), l'app mostra il messaggio «Nota non esportata: impossibile scrivere il file nella posizione scelta.»; nessun file viene creato e i dati della nota non cambiano.

## What should happen

Il Model descrive solo due esiti della finestra di salvataggio: file scritto con il messaggio di conferma, oppure annullamento senza effetti. Il messaggio di errore non compare né nel Model né nel Requirement, anche se la Drift fb5uvqun (risolta) aveva scelto proprio questa soluzione e ne prevedeva la descrizione nel Model.

## Fix options

### Descrivere il messaggio di errore nel Model

Il Model aggiunge l'esito di errore: messaggio «Nota non esportata: impossibile scrivere il file nella posizione scelta.», nessun file creato, dati invariati, e l'utente può riprovare dal menu della nota. Nessun cambio di codice.

### Non mostrare nulla in caso di errore

Il fallimento resta silenzioso: si rimuove il messaggio dal codice e il Model lo dichiara in modo esplicito. Costo: l'utente può credere che l'esportazione sia riuscita.

### Riaprire la finestra di salvataggio

Dopo il messaggio di errore la finestra di salvataggio si riapre con lo stesso nome proposto, così l'utente può scegliere un'altra posizione; il Model descrive il ciclo e l'uscita quando l'utente rinuncia.

## Where in the code

lib/ui/notes_list/note_actions.dart, ramo NoteMenuAction.export: catch intorno a FilePicker.saveFile
