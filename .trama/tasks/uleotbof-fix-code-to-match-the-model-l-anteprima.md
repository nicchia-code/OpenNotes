---
column: done
technical: false
refs:
  - requirements/rules#note
  - note/Active
drift: j7ta4iur
proposal: null
agent: false
created: 2026-10-12T18:00:24.515Z
finished: 2026-10-12T18:04:49.907Z
---
# Fix code to match the Model: L'anteprima della nota mostra il nome del file delle immagini

## What happens

Una nota con un'immagine o un disegno nel contenuto mostra nell'anteprima, nell'elenco delle note, il percorso del file dell'immagine, per esempio «attachments/att_…png», accanto al testo scritto dall'utente.

## What should happen

Il Requirement dice che l'anteprima unisce i testi non vuoti dei blocchi successivi al titolo. Per il titolo esclude già immagini e tabelle, ma per l'anteprima non dice se un'immagine conti come testo, e il Model non lo dice.

## Chosen option

**Escludere le immagini dall'anteprima**

L'anteprima salta i blocchi immagine, come già fa per il titolo, e mostra solo il testo scritto. Una nota con sole immagini mostra «Nessun testo aggiuntivo». Il file resta nel vault e nel cloud. Costo: il Requirement va precisato su questo punto e l'anteprima perde il riferimento visivo all'immagine.

## Where in the code

lib/core/models/note_model.dart: extractSnippet, ramo dei documenti a blocchi; lib/ui/editor/notion_document_editor.dart: insertImage (il testo del blocco immagine è il percorso del file)
