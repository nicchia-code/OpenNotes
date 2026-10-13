---
status: resolved
resolution: proposal
refs:
  - note-editor/Protected
  - requirements/rules#note-editor
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ccg944lf
created: 2026-10-12T12:08:54.847Z
---
# Model has no exit for the remote version of a hidden protected note

## What happens

Con la nota protetta e nascosta, una versione remota diversa dall'ultima consegnata dall'editor, senza riga con il focus, ricarica il documento nascosto. Il codice lo fa così, anche dopo che il Drift 7jao0w40 ha scelto questo comportamento.

## What should happen

Il Modello, nello stato protetto, non prevede nulla per la versione remota: lì la versione remota non ha alcuna uscita, quindi viene ignorata. La risoluzione approvata nella Proposta 3pikg137 chiedeva invece di aggiungere allo stato protetto l'uscita «versione remota» verso sé stesso. Quell'aggiunta non è mai entrata nel Modello, che quindi descrive un comportamento diverso da quello scelto.

## Fix options

### Aggiungere l'uscita nel Modello, come deciso

Lo stato protetto riceve l'uscita verso sé stesso per la versione remota diversa e senza focus, che ricarica il documento nascosto. Il codice resta com'è. Il Modello dice ciò che la nota fa davvero, e la decisione approvata viene applicata. Costo: una Proposta di modifica del Modello da approvare.

### Ignorare la versione remota finché la nota è nascosta

Il documento nascosto non riceve versioni remote e, allo sblocco, si carica l'ultima versione. Il Modello resta com'è, e il codice cambia: se la nota è protetta e non sbloccata, il caricamento della versione remota viene saltato. Costo: fino allo sblocco il documento in memoria può restare indietro, e lo sblocco deve caricarlo.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo in cui il contenuto della nota cambia e nessuna riga ha il focus.
