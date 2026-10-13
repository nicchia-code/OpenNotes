---
column: done
technical: false
refs:
  - mobile-navigation/Editor from list
drift: w1z2zzqd
proposal: null
agent: false
created: 2026-10-12T07:38:53.737Z
finished: 2026-10-12T07:45:13.758Z
---
# Fix code to match the Model: Editor shows stale note after leaving the list

## What happens

Quando la nota esce dalla selezione corrente, per esempio dopo lo spostamento in un'altra cartella o il ripristino dal cestino, o sparisce dai dati, l'editor torna a mostrare la nota com'era al momento dell'apertura, non la sua ultima versione. Se il testo non ha il fuoco, le modifiche fatte nella sessione risultano annullate sullo schermo.

## What should happen

L'editor resta aperto dopo lo spostamento, la fissatura o il ripristino, e se la nota sparisce dai dati resta mostrata la sua ultima versione.

## Chosen option

**Mantenere l'ultima versione ricevuta**

L'editor continua a mostrare l'ultima versione che ha ricevuto dalla lista, anche quando la nota non è più nella selezione. Coerente con il Model e poco codice; richiede che la copia dell'ultima versione resti disponibile per tutta la sessione dell'editor.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (build, fallback su widget.note); lib/ui/editor/notion_document_editor.dart (didUpdateWidget)
