---
status: resolved
resolution: proposal
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
proposal: null
task: null
origin: null
previous: ejiz1n2v
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:33:46.246Z
---
# Failed Markdown file write has no outcome in the Model

## What happens

Se la scrittura del file fallisce dopo la scelta della posizione (cartella di sola lettura, disco pieno, percorso non raggiungibile), l'app mostra il messaggio «Nota non esportata: impossibile scrivere il file nella posizione scelta.», non crea alcun file e lascia invariati i dati della nota. Il Model descrive solo due esiti della finestra di salvataggio: file scritto con il messaggio di conferma, oppure annullamento senza effetti.

## What should happen

Il Model dovrebbe descrivere anche l'esito di errore di scrittura, con il messaggio, nessun file creato e dati invariati, come deciso nella Drift ejiz1n2v; la Drift risolta non ha però modificato il Model.

## Fix options

### Descrivere il messaggio di errore nel Model

Il Model aggiunge da Choosing destination un ramo di errore verso Idle con il messaggio «Nota non esportata: impossibile scrivere il file nella posizione scelta.», nessun file creato e dati invariati. Nessun cambio di codice.

### Non mostrare nulla in caso di errore

Si rimuove il messaggio dal codice e il Model dichiara che il fallimento è silenzioso. Costo: l'utente può credere che l'esportazione sia riuscita.

### Riaprire la finestra di salvataggio

Dopo il messaggio di errore la finestra si riapre con lo stesso nome proposto; il Model descrive il ciclo e l'uscita quando l'utente rinuncia.

## Where in the code

lib/ui/notes_list/note_actions.dart, ramo NoteMenuAction.export: errore di FilePicker.saveFile
