---
column: done
technical: false
refs:
  - note-editor/Open/sync-run.CLOUD_NOTE_APPLIED
  - note-editor/Open/realtime-channel.CLOUD_NOTE_APPLIED
  - note-editor/Open
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-12T08:27:48.754Z
finished: 2026-10-12T10:25:39.143Z
---
# Fix code to match the Model: Open note on desktop does not receive remote changes, date or tags

Con una nota aperta nella colonna editor di destra, le modifiche arrivate dalla sincronizzazione o dal canale in tempo reale devono raggiungere l'editor come su mobile: se il contenuto remoto è diverso dall'ultimo salvato dall'editor e nessuna riga di testo ha il focus, il documento viene ricaricato, scartando la modifica in attesa e chiudendo i menu; altrimenti la versione remota è ignorata. Mentre la nota è aperta, anche la data dell'ultima modifica e i tag mostrati nell'intestazione devono aggiornarsi dopo ogni modifica, senza dover riselezionare la nota. Oggi la colonna editor riceve la nota solo quando cambiano la nota selezionata o il suo stato di protezione, quindi le modifiche remote non arrivano e l'editor può salvare sopra di esse.
