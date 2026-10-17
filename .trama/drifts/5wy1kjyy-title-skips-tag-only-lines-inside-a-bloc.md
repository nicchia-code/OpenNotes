---
status: resolved
resolution: proposal
refs:
  - requirements/rules#note-content-save
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:45:18.041Z
---
# Title skips tag-only lines inside a block, the Requirement skips only tag-only blocks

## What happens

Il titolo salta ogni riga fatta solo di tag, anche quando sta dentro un blocco che ha altro testo. Così una nota che comincia con «#lavoro» e continua con «Riunione» prende «Riunione» come titolo. Lo stesso accade nel testo semplice, dove una riga di soli tag in cima viene saltata.

## What should happen

Il Requirement dice che il titolo è la prima riga del primo blocco con testo e che vengono saltati i blocchi fatti solo di tag. Un blocco con «#lavoro» e poi «Riunione» non è fatto solo di tag, quindi la regola letterale dà «lavoro» come titolo. Il Requirement non prevede di saltare le singole righe di tag: codice e Requirement non coincidono.

## Fix options

### Saltare solo i blocchi fatti di soli tag

Il titolo segue il Requirement alla lettera: una riga di soli tag dentro un blocco con altro testo diventa il titolo, quindi una nota che comincia con «#lavoro» prende «lavoro». Costo: le note che iniziano con una riga di tag prendono quel tag come titolo, e il test che fissa il comportamento attuale va cambiato.

### Mantenere il salto delle righe di soli tag

Il codice e il test restano come sono. Costo: il Requirement continua a dire una cosa diversa da ciò che l'app fa, e la differenza resta aperta finché la regola non viene chiarita.

## Where in the code

lib/core/models/note_model.dart: _titleLineIndex, usata da extractTitle ed extractSnippet; test/vault_test.dart: test del titolo che salta la riga di tag
