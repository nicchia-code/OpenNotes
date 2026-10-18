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
resolvedBy: famz2y49
created: 2026-10-18T18:31:01.441Z
---
# Tag after square or curly bracket is accepted, the Requirement allows only space or parenthesis

## What happens

Il codice in extractTagsFromContent riconosce un «#nome» anche dopo una parentesi quadra o graffa (lookbehind con [ e {). La Requirement ammette il tag solo all'inizio del testo, dopo uno spazio o dopo una parentesi.

## What should happen

Il riconoscimento dei tag segue la Requirement: inizio del testo, spazio o parentesi tonda, nel testo e nelle celle delle tabelle.

## Fix options

### Limit code to round parentheses

Togliere [ e { dal lookbehind della regex dei tag: il codice segue la Requirement.

### Extend Requirement to square and curly brackets

Aggiungere le parentesi quadre e graffe alla Requirement e lasciare il codice com'è.

## Where in the code

lib/core/models/note_model.dart, extractTagsFromContent
