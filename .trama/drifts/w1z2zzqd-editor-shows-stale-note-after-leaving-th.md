---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Editor from list
proposal: null
task: bsx6yj72
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:29.724Z
---
# Editor shows stale note after leaving the list

## What happens

Quando la nota esce dalla selezione corrente, per esempio dopo lo spostamento in un'altra cartella o il ripristino dal cestino, o sparisce dai dati, l'editor torna a mostrare la nota com'era al momento dell'apertura, non la sua ultima versione. Se il testo non ha il fuoco, le modifiche fatte nella sessione risultano annullate sullo schermo.

## What should happen

L'editor resta aperto dopo lo spostamento, la fissatura o il ripristino, e se la nota sparisce dai dati resta mostrata la sua ultima versione.

## Fix options

### Mantenere l'ultima versione ricevuta

L'editor continua a mostrare l'ultima versione che ha ricevuto dalla lista, anche quando la nota non è più nella selezione. Coerente con il Model e poco codice; richiede che la copia dell'ultima versione resti disponibile per tutta la sessione dell'editor.

### Rileggere la nota dai dati locali

Se la nota non è più nella selezione, l'editor la legge dal database e mostra la versione salvata. Corretto anche per le note sparite dai dati, ma serve una lettura asincrona e un caso di attesa da gestire. Costo maggiore, stesso risultato visibile.

### Cambiare il Model: versione all'apertura

Si accetta che l'editor mostri la nota com'era all'apertura e si riscrive la frase del Model. Nessuna modifica al codice, ma le modifiche fatte nella sessione risultano nascoste dopo lo spostamento.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (build, fallback su widget.note); lib/ui/editor/notion_document_editor.dart (didUpdateWidget)
