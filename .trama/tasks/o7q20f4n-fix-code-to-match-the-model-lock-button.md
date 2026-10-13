---
column: done
technical: false
refs:
  - mobile-navigation/Editor from list
drift: u2qtxr20
proposal: null
agent: false
created: 2026-10-12T08:09:28.395Z
finished: 2026-10-12T08:14:18.789Z
---
# Fix code to match the Model: Lock button ignores the last version of a note that left the list

## What happens

Quando la nota esce dalla selezione corrente, per esempio dopo lo spostamento in un'altra cartella, l'editor continua a mostrare l'ultima versione ricevuta, con il lucchetto aggiornato. Il pulsante di protezione però decide cosa fare leggendo la nota com'era al momento dell'apertura. Se nel frattempo la nota è stata protetta, il pulsante la tratta come non protetta: con il PIN principale già impostato, **toglie il lucchetto senza chiedere il PIN**.

## What should happen

Il pulsante di protezione deve agire sulla stessa versione della nota che l'editor mostra. Togliere il lucchetto richiede sempre il PIN principale corretto, anche quando la nota è già sbloccata per la sessione, e spostare la nota non deve cambiare ciò che il pulsante fa.

## Chosen option

**Agire sull'ultima versione mostrata**

Il pulsante di protezione usa la stessa versione che l'editor mostra, come già fanno il menu e la condivisione. Togliere il lucchetto chiede il PIN e mettere il lucchetto funziona come adesso. Piccola modifica, coerente con il Model; nessun costo per l'utente.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (_onLock: la nota di partenza è widget.note quando non è più nella lista, invece dell'ultima versione ricevuta)
