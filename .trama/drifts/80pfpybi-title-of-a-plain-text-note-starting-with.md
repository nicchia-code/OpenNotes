---
status: resolved
resolution: proposal
refs:
  - requirements/rules#note
  - requirements/rules#note-content-save
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:09:03.736Z
---
# Title of a plain-text note starting with [ is set by two Requirements that disagree

## What happens

Una nota di testo semplice che inizia con «[» e non è un elenco valido riceve come titolo la sua prima riga, per esempio «[Spesa] latte». Il codice segue la regola dell'editor, e un test lo verifica.

## What should happen

Il Requirement delle note dice che, se il contenuto inizia con «[» ma non è un elenco JSON valido, il titolo è quello predefinito «Nuova nota». Il Requirement dell'editor dice invece che una nota di testo semplice prende sempre il titolo dalla sua prima riga. Per questo caso i due Requirement dicono cose diverse, e non è chiaro quale valga.

## Fix options

### Tenere il titolo dalla prima riga

Il titolo di una nota di testo semplice resta la sua prima riga, anche quando inizia con «[». Il Requirement delle note va corretto togliendo la frase sul titolo predefinito, e il codice non cambia. Costa una modifica del Requirement da approvare; le note che iniziano con «[» mostrano il proprio testo come titolo, come oggi.

### Titolo predefinito per il contenuto non valido

Un contenuto che inizia con «[» e non è un elenco JSON valido mostra «Nuova nota» come titolo, come scrive il Requirement delle note. Il codice va cambiato in questo caso e la regola dell'editor va corretta. Costa: «[Spesa] latte» compare nell'elenco senza titolo finché il contenuto non cambia, e un test va riscritto.

## Where in the code

lib/core/models/note_model.dart (extractTitle); test/vault_test.dart (extractTitle uses the first line of plain text starting with [)
