---
column: done
technical: false
refs:
  - note-browser/Browsing
drift: 2vxdka3s
proposal: null
agent: false
created: 2026-10-12T07:38:53.837Z
finished: 2026-10-12T07:42:23.557Z
---
# Fix code to match the Model: Note list not reloaded after saving note text

## What happens

Quando scrivi nel testo di una nota, la nota viene aggiornata nell'elenco ma l'elenco non viene riletto. Così la nota resta nella posizione di prima della modifica e resta visibile anche se, dopo la modifica, non ha più il tag scelto o non contiene più il testo cercato.

## What should happen

Il Model dice che l'elenco viene riletto dopo ogni salvataggio di una nota. Una nota modificata deve salire in cima per data di modifica e uscire dal filtro se non rispetta più la vista, il tag o la ricerca scelti.

## Chosen option

**Rileggere l'elenco dopo ogni salvataggio**

Dopo il salvataggio automatico l'elenco viene riletto dal database, come prevede il Model. La nota modificata si sposta nella posizione giusta e sparisce dal filtro se non lo rispetta più. Costo: l'elenco può cambiare mentre si scrive, quindi la nota aperta nell'editor deve restare ferma.

## Where in the code

lib/core/state/notes_provider.dart, updateNoteContent: il salvataggio ritardato aggiorna la nota solo in memoria e nel database, senza rileggere l'elenco.
