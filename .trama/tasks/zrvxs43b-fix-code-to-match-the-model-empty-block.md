---
column: done
technical: false
refs:
  - text-line/Title
drift: 7panlske
proposal: null
agent: false
created: 2026-10-12T09:03:39.580Z
finished: 2026-10-12T09:05:04.084Z
---
# Fix code to match the Model: Empty block-format note loads its raw JSON as a Title line

## What happens

Una nota salvata dall'editor come documento a blocchi, ma con soli blocchi di testo vuoti (per esempio una nota svuotata dall'utente), alla riapertura non mostra una sezione di testo vuota: mostra il contenuto salvato come testo, cioè una riga lunga con l'elenco dei blocchi scritto in chiaro, e quella riga riceve lo stile **Titolo**. Il caricamento tratta il documento come nota in formato precedente, anche se è in formato a blocchi. Un documento vuoto senza alcun blocco invece si carica bene.

## What should happen

Una nota in **formato a blocchi** non è mai in formato precedente: lo stile Titolo va solo alla prima riga significativa di una nota in formato precedente, o alla prima riga di una sezione che comincia con «# ». Un documento senza parti riceve già una sezione di testo vuota (requisito di caricamento JSON in rules/editor), e un documento con un solo blocco di testo vuoto deve aprirsi allo stesso modo, senza testo estraneo e senza Titolo.

## Chosen option

**Load a block list with no text as an empty text section**

Quando l'elenco di blocchi è valido ma non produce alcuna sezione di testo, il caricamento crea la sezione di testo vuota, come già accade per un elenco senza blocchi. Il ripiego sul testo grezzo resta solo per il contenuto che non è un elenco di blocchi valido. Costo: una modifica piccola al caricamento; le note già salvate in questo stato si correggono alla riapertura, senza migrazioni di dati.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _parseContentToBlocks: la funzione flushText non crea il blocco di testo quando tutti i blocchi di testo sono vuoti, quindi la condizione che decide il ripiego sul testo grezzo (mergedBlocks vuoto) resta vera.
