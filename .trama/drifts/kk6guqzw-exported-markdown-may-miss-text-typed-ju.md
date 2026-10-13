---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Idle/user.EXPORT_NOTE_AS_MARKDOWN
proposal: null
task: 43152a07
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:49:30.485Z
---
# Exported Markdown may miss text typed just before the export

## What happens

Il file esportato contiene la versione della nota già salvata. Il testo digitato negli ultimi istanti può mancare: l'editor consegna le modifiche dopo circa 300 ms, e la scrittura nel database avviene dopo altri 400 ms. Dal telefono il menu legge la versione nel database; sul desktop quella in memoria, già aggiornata dalla consegna dell'editor. Nessun avviso se manca testo.

## What should happen

Il Model dice che il file contiene il contenuto della nota, ma non dice quale versione si esporta quando una modifica è ancora in attesa di essere salvata. Per i comandi di formattazione l'editor consegna il testo subito; per l'esportazione il Model tace. Se l'utente vede un testo e il file ne contiene uno più vecchio, la differenza è visibile e non è dichiarata.

## Fix options

### Consegnare il testo in attesa prima di esportare

Quando l'utente sceglie l'esportazione, l'editor consegna subito la modifica in attesa, come fanno i comandi di formattazione. Il file contiene allora tutto ciò che è visibile sullo schermo. Costo: un salvataggio anticipato a ogni esportazione, senza effetti sui dati conservati.

### Esportare il testo mostrato

L'esportazione prende il testo che l'editor mostra in quel momento, non la versione salvata. Costo: l'esportazione su file usa una regola diversa da quella della versione salvata della nota e va descritta nel Model.

### Dichiarare la versione salvata

Il Model dichiara che l'esportazione usa l'ultima versione salvata, e che il testo digitato negli ultimi istanti può mancare. Costo: il file può non avere gli ultimi caratteri digitati, e l'utente deve saperlo.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart, menu azioni (fetchNote); lib/core/state/notes_provider.dart, aggiornamento del contenuto con ritardo di 400 ms; lib/ui/editor/notion_document_editor.dart, consegna con ritardo di 300 ms
