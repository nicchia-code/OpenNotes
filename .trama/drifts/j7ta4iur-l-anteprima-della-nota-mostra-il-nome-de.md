---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note
  - note/Active
proposal: null
task: uleotbof
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:55:18.741Z
---
# L'anteprima della nota mostra il nome del file delle immagini

## What happens

Una nota con un'immagine o un disegno nel contenuto mostra nell'anteprima, nell'elenco delle note, il percorso del file dell'immagine, per esempio «attachments/att_…png», accanto al testo scritto dall'utente.

## What should happen

Il Requirement dice che l'anteprima unisce i testi non vuoti dei blocchi successivi al titolo. Per il titolo esclude già immagini e tabelle, ma per l'anteprima non dice se un'immagine conti come testo, e il Model non lo dice.

## Fix options

### Escludere le immagini dall'anteprima

L'anteprima salta i blocchi immagine, come già fa per il titolo, e mostra solo il testo scritto. Una nota con sole immagini mostra «Nessun testo aggiuntivo». Il file resta nel vault e nel cloud. Costo: il Requirement va precisato su questo punto e l'anteprima perde il riferimento visivo all'immagine.

### Mostrare un segnaposto al posto del percorso

L'anteprima scrive una parola fissa, per esempio «immagine», al posto del percorso del file, nel punto in cui il blocco compare. Il nome del file non compare più nell'elenco. Costo: serve una regola nel Requirement e un ritocco all'anteprima; il testo dell'utente resta invariato.

### Mantenere il percorso nell'anteprima

Il comportamento attuale resta e il Requirement lo dichiara esplicitamente. Costo: nessun cambiamento al codice, ma il nome del file, poco leggibile, compare nelle liste di tutte le note con immagini, anche in quelle senza altro testo.

## Where in the code

lib/core/models/note_model.dart: extractSnippet, ramo dei documenti a blocchi; lib/ui/editor/notion_document_editor.dart: insertImage (il testo del blocco immagine è il percorso del file)
