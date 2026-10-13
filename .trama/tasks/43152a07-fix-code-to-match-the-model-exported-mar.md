---
column: done
technical: false
refs:
  - export-markdown-file/Idle/user.EXPORT_NOTE_AS_MARKDOWN
drift: kk6guqzw
proposal: null
agent: false
created: 2026-10-12T14:57:05.746Z
finished: 2026-10-12T15:02:04.495Z
---
# Fix code to match the Model: Exported Markdown may miss text typed just before the export

## What happens

Il file esportato contiene la versione della nota già salvata. Il testo digitato negli ultimi istanti può mancare: l'editor consegna le modifiche dopo circa 300 ms, e la scrittura nel database avviene dopo altri 400 ms. Dal telefono il menu legge la versione nel database; sul desktop quella in memoria, già aggiornata dalla consegna dell'editor. Nessun avviso se manca testo.

## What should happen

Il Model dice che il file contiene il contenuto della nota, ma non dice quale versione si esporta quando una modifica è ancora in attesa di essere salvata. Per i comandi di formattazione l'editor consegna il testo subito; per l'esportazione il Model tace. Se l'utente vede un testo e il file ne contiene uno più vecchio, la differenza è visibile e non è dichiarata.

## Chosen option

**Consegnare il testo in attesa prima di esportare**

Quando l'utente sceglie l'esportazione, l'editor consegna subito la modifica in attesa, come fanno i comandi di formattazione. Il file contiene allora tutto ciò che è visibile sullo schermo. Costo: un salvataggio anticipato a ogni esportazione, senza effetti sui dati conservati.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart, menu azioni (fetchNote); lib/core/state/notes_provider.dart, aggiornamento del contenuto con ritardo di 400 ms; lib/ui/editor/notion_document_editor.dart, consegna con ritardo di 300 ms
