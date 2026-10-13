# Markdown File Export

Il salvataggio di una nota, convertita in Markdown, come file in una posizione scelta dall'utente. Si avvia dal menu azioni di una nota attiva (desktop e mobile).

## States

### Idle (initial)
Nessuna esportazione in corso.
- `user.EXPORT_NOTE_AS_MARKDOWN` → Awaiting PIN: solo se la nota è protetta; chiede il PIN principale ogni volta, anche se la nota è già stata sbloccata in questa sessione.
- `user.EXPORT_NOTE_AS_MARKDOWN` → Choosing destination: se la nota non è protetta; apre la finestra di salvataggio del sistema con un nome proposto ricavato dal titolo e il contenuto della nota convertito in Markdown.

### Awaiting PIN
È aperta la richiesta del PIN principale per poter esportare una nota protetta.
- `user.ENTER_PIN` → Choosing destination: se il PIN è corretto; apre la finestra di salvataggio del sistema con un nome proposto ricavato dal titolo e il contenuto della nota convertito in Markdown.
- `user.ENTER_PIN` → Awaiting PIN: se il PIN è sbagliato mostra un errore e resta in attesa; un PIN vuoto viene ignorato.
- `user.CANCEL_PIN_ENTRY` → Idle: non esporta nulla.

### Choosing destination
La finestra di salvataggio del sistema è aperta e l'utente sceglie dove salvare il file.
- `operating-system.FILE_SAVE_DIALOG_CLOSED` → Idle: se l'utente ha scelto una posizione il file viene scritto lì e l'app mostra un breve messaggio con il nome del file esportato; se ha annullato non succede nulla.
