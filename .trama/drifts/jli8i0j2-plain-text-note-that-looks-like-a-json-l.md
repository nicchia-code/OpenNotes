---
status: resolved
resolution: fix-code
refs:
  - requirements/data#note-editor
proposal: null
task: se7pway1
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:17:33.682Z
---
# Plain-text note that looks like a JSON list opens empty in the editor

## What happens

Una nota di testo semplice la cui prima riga è un elenco JSON valido ma non di soli oggetti, per esempio «[1]», si apre nell'editor come documento vuoto. Il testo sparisce dalla vista e, alla prima modifica, viene sostituito dal documento vuoto salvato.

## What should happen

Secondo i requisiti, un contenuto che non è un elenco JSON i cui elementi sono tutti oggetti viene letto come testo semplice, come nel formato precedente. Il testo deve restare visibile e modificabile, senza perdite.

## Fix options

### Usare la stessa regola di riconoscimento in tutta l'app

L'editor, il titolo e l'anteprima usano la stessa verifica: un elenco vale come blocchi solo se tutti gli elementi sono oggetti. Il testo «[1]» si apre come testo e mostra il proprio contenuto. Costo: la verifica del formato va condivisa e il caricamento cambia in più punti.

### Correggere solo l'apertura nell'editor

Il caricamento dell'editor legge il testo come Markdown quando l'elenco non è di soli oggetti, mentre titolo e anteprima restano invariati. Costo: per queste note il titolo e il contenuto mostrato possono non coincidere, e la regola resta duplicata in due punti.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _parseContentToBlocks (lettura del contenuto come blocchi JSON)
