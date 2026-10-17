---
status: resolved
resolution: proposal
refs:
  - requirements/rules#note-editor
proposal: null
task: null
origin: 1paindhq
previous: ytz0a6hu
critical: false
option: null
note: null
resolvedBy: rpuwm3sy
created: 2026-10-17T10:36:55.343Z
---
# Remote version with a focused line: Model and Requirement disagree

## What happens

Con una riga di testo o una cella di tabella a fuoco, la versione remota della nota non viene caricata: la modifica fatta su un altro dispositivo non compare nella nota aperta finché il cursore resta in quella riga.

## What should happen

Il Modello (Proposta 634nfp49, approvata) dice che, senza modifiche in attesa, la versione remota si carica anche con una riga a fuoco, e il cursore resta dov'è. Il Requisito dell'editor dice invece che la versione remota si carica solo se nessuna riga ha il focus. Le due regole non si possono seguire insieme: nessuna correzione del codice rispetta entrambe, quindi la Proposta allinea il Requisito al Modello.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo in cui il contenuto della nota cambia; la condizione che salta il caricamento usa il focus delle righe (_hasActiveFocus)
