---
status: approved
base:
  editor/note-editor.md: 6ab749bbad74685c95a09906c3e079c4ab9a5e8f53680df7a8d343cbbe410b53
  requirements/rules/editor.md: adfbba4767d4e7e0fe4cfd23ca9d2a0ee2634aa0aec397f51f67c73fa7fc8de1
  requirements/ui/editor.md: b2e07a391364aafaeb3d1e557bb62b493f1f28ecf2ea10f7af0c17e2bab8d1ef
delete: []
request: 2026-10-19T19-30-29
created: 2026-10-19T17:45:32.916Z
label: Incolla immagine al cursore
---
# Immagine incollata al cursore

L'immagine incollata deve andare dove si trova il cursore, non dopo l'intera sezione di testo attiva (richiesta dello sviluppatore).

Decisioni:
- Solo l'immagine incollata va al cursore; foto scelta da file e disegno restano dopo la parte attiva.
- L'immagine va esattamente nel punto del cursore: la sezione di testo si divide lì, anche a metà riga.
- Con del testo selezionato, l'immagine sostituisce la selezione.
- Divisione letterale: restano sempre una sezione di testo sopra e una sotto l'immagine, anche se vuote.
- Dopo l'incolla il cursore va all'inizio del testo sotto l'immagine.
- Vale il punto in cui l'utente ha incollato, adattato alle modifiche fatte nel frattempo mentre l'immagine viene salvata.
- Rimuovendo poi l'immagine le due sezioni restano separate (si uniscono con Backspace, come oggi).
- A metà di una riga con uno stile, il testo che passa sotto l'immagine segue le regole di continuazione di Invio.
- All'inizio o alla fine di una riga l'a capo nel punto di divisione si toglie, così non restano righe vuote in più.
- Se nel frattempo la sezione non esiste più ma la nota è la stessa, l'immagine va dopo la parte attiva come oggi; se è aperta un'altra nota o nessuna, non viene inserita e compare «Immagine non incollata».

Assunzioni:
- Con il cursore alla fine di una riga (anche l'ultima della sezione) non si crea una nuova voce: le regole di Invio valgono solo quando il cursore ha del testo dopo di sé nella riga.
- Se il punto di divisione è su una riga vuota tra due righe, si toglie un solo a capo, quello che chiude il testo sopra.
