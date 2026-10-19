---
column: done
technical: false
refs:
  - note-editor/Open/user.PASTE_IMAGE
  - requirements/rules#note-editor
  - requirements/ui#note-editor
drift: null
proposal: l4fblwaa
agent: false
created: 2026-10-19T17:46:42.896Z
finished: 2026-10-19T17:58:18.685Z
---
# Incolla immagine al cursore

Quando l'utente incolla un'immagine in una sezione di testo (Ctrl/Cmd+V o voce «Incolla» del menu contestuale) e l'immagine viene salvata tra gli allegati del vault, l'immagine entra nel documento nel punto in cui era il cursore al momento dell'incolla, non più dopo l'intera parte attiva. Foto scelta da file e disegno non cambiano: restano dopo la parte attiva, seguiti da una nuova sezione vuota.

Deve valere:

- Il punto è quello del momento dell'incolla; se mentre l'immagine viene preparata e salvata il testo della sezione cambia prima di quel punto, il punto si sposta con il testo.
- Con del testo selezionato, l'immagine lo sostituisce: il testo selezionato viene tolto e il punto è l'inizio della selezione.
- La sezione si divide nel punto: il testo prima resta nella sezione esistente, sopra l'immagine; il testo dopo passa in una nuova sezione sotto l'immagine. Le due sezioni restano anche se vuote (cursore all'inizio o alla fine della sezione, oppure sezione vuota).
- Si toglie al più un a capo nel punto di divisione: quello che chiude il testo sopra, se c'è, altrimenti quello che apre il testo sotto; così non restano righe vuote in più.
- La formattazione dei caratteri e gli stili di riga seguono il testo, ricalcolati sulle posizioni della nuova sezione.
- Se il punto è a metà di una riga (testo sia prima sia dopo nella stessa riga), la prima parte tiene il tipo della riga e la parte che passa sotto l'immagine segue le regole di Invio senza Maiuscole: checklist → nuova voce «○ » con lo stesso rientro, voce puntata → simbolo del livello, voce numerata → «N+1. » con lo stesso rientro, titolo e intestazioni → corpo, citazione, monospazio e corpo → corpo senza simbolo. All'inizio o alla fine di una riga nessuna riga cambia tipo.
- Il cursore va all'inizio della nuova sezione sotto l'immagine, che riceve il focus, e il documento si salva subito.
- Se quando l'immagine è salvata la sezione in cui si è incollato non esiste più (unita con Backspace o ricaricata) ma la nota aperta è la stessa, l'immagine va dopo la parte attiva, seguita da una nuova sezione di testo vuota che riceve il focus.
- Se nel frattempo è stata aperta un'altra nota o nessuna, l'immagine non viene inserita in nessuna nota (il file resta tra gli allegati) e compare l'avviso «Immagine non incollata».
- Rimuovendo poi l'immagine, le due sezioni restano separate.
