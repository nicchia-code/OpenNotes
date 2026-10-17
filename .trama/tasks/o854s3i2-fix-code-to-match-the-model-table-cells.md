---
column: done
technical: false
refs:
  - note-editor/Idle
  - requirements/rules#note-editor
drift: c23bbpp3
proposal: null
agent: false
created: 2026-10-17T14:48:35.570Z
finished: 2026-10-17T14:53:06.796Z
---
# Fix code to match the Model: Table cells keep their old text after a remote reload

## What happens

Quando una versione remota della nota viene caricata mentre la nota è aperta, la tabella non si aggiorna: le celle mostrano ancora il testo di prima del caricamento, anche se il documento contiene già quello ricevuto. Se si scrive in una di quelle celle, il testo vecchio mostrato sostituisce il valore ricevuto per quella cella. Inoltre le frecce che entrano nella tabella dalle sezioni di testo vicine non la raggiungono, finché la tabella non viene ricreata, per esempio riaprendo la nota.

## What should happen

Il Modello dice che la versione remota ricarica il documento della nota aperta: la tabella deve mostrare il contenuto ricevuto. La Requirement dice che la versione remota si carica anche con una riga a fuoco e che il cursore resta dove era, senza eccezioni per le celle. Il collegamento della tabella al documento deve restare attivo, come prima del caricamento.

## Chosen option

**Ricreare la tabella quando arriva una versione remota**

La tabella viene ricostruita ogni volta che il documento viene ricaricato, con i valori ricevuti e i collegamenti nuovi. Una cella con il cursore torna alla stessa cella e posizione, come le righe di testo. Costo: mentre si scrive in una cella la tabella perde il focus per un istante, poi il cursore viene rimesso dal caricamento. Il Modello non cambia.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _InteractiveTableBlockState. didUpdateWidget ricalcola le celle solo se cambiano righe o colonne; initState collega i comandi della tabella (focusCell, cellCaret, focusCellAt) solo al primo montaggio, sul blocco di allora. La tabella ha la stessa chiave del blocco, quindi lo stato resta quando la nota viene ricaricata da una versione remota, e il blocco nuovo non ha più quei comandi.
