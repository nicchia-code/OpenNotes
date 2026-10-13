---
status: resolved
resolution: fix-code
refs:
  - note-browser/Browsing
proposal: null
task: md7yfmnm
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:34:41.662Z
---
# Note list not reloaded after saving note text

## What happens

Quando scrivi nel testo di una nota, la nota viene aggiornata nell'elenco ma l'elenco non viene riletto. Così la nota resta nella posizione di prima della modifica e resta visibile anche se, dopo la modifica, non ha più il tag scelto o non contiene più il testo cercato.

## What should happen

Il Model dice che l'elenco viene riletto dopo ogni salvataggio di una nota. Una nota modificata deve salire in cima per data di modifica e uscire dal filtro se non rispetta più la vista, il tag o la ricerca scelti.

## Fix options

### Rileggere l'elenco dopo ogni salvataggio

Dopo il salvataggio automatico l'elenco viene riletto dal database, come prevede il Model. La nota modificata si sposta nella posizione giusta e sparisce dal filtro se non lo rispetta più. Costo: l'elenco può cambiare mentre si scrive, quindi la nota aperta nell'editor deve restare ferma.

### Rileggere l'elenco solo al cambio di vista

Il Model viene riscritto: dopo una modifica del testo l'elenco resta com'è finché l'utente non cambia vista, tag o ricerca. Nessun salto mentre si scrive e nessuna modifica al codice. Costo: una nota può restare in un filtro che non la contiene più, e l'ordine per data di modifica non è aggiornato.

## Where in the code

lib/core/state/notes_provider.dart, updateNoteContent: il salvataggio ritardato aggiorna la nota solo in memoria e nel database, senza rileggere l'elenco.
