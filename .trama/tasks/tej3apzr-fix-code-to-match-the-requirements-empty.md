---
column: done
technical: false
refs:
  - note-editor/Open
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-13T10:46:12.718Z
finished: 2026-10-13T10:52:45.510Z
---
# Fix code to match the Requirements: Empty text section between tables is dropped when the note loads

## What happens

Quando una nota viene caricata dal contenuto JSON, una sezione di testo vuota che sta tra una tabella (o un'immagine, o un separatore) e la parte successiva viene eliminata. Succede anche a una sezione vuota in fondo al documento che segue una tabella: il documento salvato dall'editor la conserva, ma alla riapertura non compare più. Così la parte attiva all'apertura può essere la tabella anziché la sezione vuota che la segue.

## What should happen

La Requirement dice che i blocchi di testo consecutivi (tutti tranne tabella, immagine e separatore) si fondono in un'unica sezione di testo, e che un documento senza parti riceve una sezione di testo vuota solo quando non ha parti. Un blocco di testo vuoto è comunque un blocco di testo: la sua sezione resta nel documento, come la sezione che l'editor aggiunge dopo una tabella inserita.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _parseContentToBlocks, ramo JSON, funzione flushText. La condizione per aggiungere la sezione accetta solo testo non vuoto (currentText.isNotEmpty), quindi una serie di blocchi di testo vuoti non produce alcuna sezione.
