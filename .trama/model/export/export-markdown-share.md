# Markdown Share

La condivisione del testo di una nota, convertito in Markdown, tramite il foglio di condivisione del sistema. Si avvia dal menu azioni di una nota attiva (desktop e mobile) o dal pulsante di condivisione nell'editor mobile.

## States

### Idle (initial)
Nessuna condivisione in corso.
- `user.SHARE_NOTE` → Awaiting PIN: solo se la nota è protetta; chiede il PIN principale ogni volta, anche se la nota è già stata sbloccata in questa sessione.
- `user.SHARE_NOTE` → Share sheet open: se la nota non è protetta; apre il foglio di condivisione con oggetto il titolo della nota e come testo il titolo, una riga vuota e il contenuto convertito in Markdown.

### Awaiting PIN
È aperta la richiesta del PIN principale per poter condividere una nota protetta.
- `user.ENTER_PIN` → Share sheet open: se il PIN è corretto; apre il foglio di condivisione con oggetto il titolo della nota e come testo il titolo, una riga vuota e il contenuto convertito in Markdown.
- `user.ENTER_PIN` → Awaiting PIN: se il PIN è sbagliato mostra un errore e resta in attesa; un PIN vuoto viene ignorato.
- `user.CANCEL_PIN_ENTRY` → Idle: non condivide nulla.

### Share sheet open
Il foglio di condivisione del sistema è aperto con il testo della nota.
- `operating-system.SHARE_SHEET_CLOSED` → Idle: l'app non distingue tra condivisione completata e annullata.
