# Time

Il passare del tempo: le attese con cui l'app rimanda un'azione finché l'utente non smette di scrivere e i tempi con cui la sincronizzazione con il cloud si ripete o riprova.

## Events

### EDITOR_SAVE_DEBOUNCE_ELAPSED
Sono passati 300 ms dall'ultima modifica di testo nell'editor.

### CONTENT_SAVE_DEBOUNCE_ELAPSED
Sono passati 400 ms dall'ultimo contenuto consegnato per il salvataggio.

### SYNC_INTERVAL_ELAPSED
È passato l'intervallo della sincronizzazione periodica. Scatta solo mentre l'app è visibile: su desktop finché la finestra è aperta e non ridotta a icona, anche senza focus; su mobile solo in primo piano.

### SYNC_RETRY_DUE
È trascorsa l'attesa programmata dopo una sincronizzazione fallita.
