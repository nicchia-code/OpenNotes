---
status: resolved
resolution: dismissed
refs:
  - note-content-save/Waiting
proposal: null
task: null
origin: null
critical: false
option: null
note: null
created: 2026-10-13T05:21:55.742Z
---
# Model still describes a replaced waiting save after its Drift was resolved

## What happens

Quando si modifica una nota mentre la modifica di un'altra nota aspetta ancora di essere scritta, il sistema scrive subito la modifica in attesa dell'altra nota e poi fa partire l'attesa per la nuova. Nessuna modifica viene persa. È il comportamento scelto nel Drift vpim0xgg, risolto dalla Proposal 32w3ze0y.

## What should happen

Il Model dice ancora che la modifica in attesa viene sostituita e che la nota precedente non viene più scritta. La stessa frase è ripetuta nella reazione di note-editor. La descrizione è rimasta quella precedente alla decisione e non è stata aggiornata dopo la risoluzione.

## Fix options

### Aggiornare il Model alla scrittura immediata

Il Model descrive la modifica in attesa scritta subito quando si passa a un'altra nota, come fa già il codice e come deciso nel Drift risolto. Nessuna modifica si perde. Costo: una scrittura in più quando si passa rapidamente da una nota all'altra. Vanno allineate la Machine note-content-save e la reazione nel Model di note-editor.

### Tornare alla sostituzione descritta nel Model

Il codice torna a sostituire la modifica in attesa della prima nota con quella della seconda, e la prima nota non viene più scritta. Costo: si perdono le modifiche fatte pochi istanti prima di passare a un'altra nota. Questa scelta contraddice la decisione già presa nel Drift vpim0xgg.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, flushPendingContent)
