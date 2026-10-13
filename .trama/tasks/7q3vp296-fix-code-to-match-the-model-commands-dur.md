---
column: done
technical: false
refs:
  - note-editor/Save pending
drift: nkmpkw76
proposal: null
agent: false
created: 2026-10-12T07:38:53.797Z
finished: 2026-10-12T07:42:31.189Z
---
# Fix code to match the Model: Commands during a pending save are not in the Model

## What happens

Mentre c'è una modifica di testo in attesa, i comandi (grassetto, corsivo, sottolineato, stile, checklist, tabella, foto, disegno, rimozione di un'immagine, tag) consegnano subito tutto il documento e l'attesa finisce. Il Modello non ha queste uscite dallo stato di attesa: da lì c'è solo la fine dell'attesa.

## What should happen

La Requirement vuole questi comandi con salvataggio immediato, quindi il comportamento è voluto. Il Modello non lo dice nello stato di attesa: un comando che arriva durante l'attesa non ha una transizione.

## Chosen option

**Aggiungere le uscite nel Modello**

Lo stato di attesa riceve l'uscita verso Inattivo per questi comandi, con «consegna subito». Il comportamento resta quello attuale, coerente con la Requirement. Costo: una voce in più nel Modello, per gruppo di comandi.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _serializeAndSave(immediate: true) annulla il timer di attesa e consegna il documento.
