---
status: resolved
resolution: fix-code
refs:
  - note-editor/Protected
proposal: null
task: s0hr7i7r
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:29:51.596Z
---
# Remote version reloads while the note is protected

## What happens

Con la nota protetta e nascosta, una versione remota diversa dall'ultima consegnata dall'editor ricarica il documento nascosto, che passa alla versione remota. Il Modello non ha questa uscita dallo stato protetto: lì non è previsto nulla per la versione remota.

## What should happen

Il Modello prevede che la versione remota sia caricata nello stato aperto. La Requirement dice che la versione remota si carica se è diversa dall'ultima consegnata e nessuna riga ha il focus, senza distinguere la nota nascosta. Da nascosto non ci sono modifiche in attesa, quindi il caricamento non perde nulla.

## Fix options

### Ricaricare anche la nota nascosta, come nel Modello

Lo stato protetto riceve l'uscita «versione remota» verso sé stesso, che ricarica il documento nascosto. È il comportamento attuale, reso esplicito nel Modello. Costo: una voce in più nel Modello, nessun cambiamento nel codice.

### Ignorare la versione remota finché la nota è nascosta

Il documento nascosto non riceve versioni remote; alla sblocco si carica l'ultima versione. Costo: fino allo sblocco il documento in memoria può restare indietro, e lo sblocco deve ricaricarlo.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo in cui il contenuto della nota cambia e nessuna riga ha il focus.
