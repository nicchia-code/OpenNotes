---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Editor from list
proposal: null
task: o7q20f4n
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:02:23.617Z
---
# Lock button ignores the last version of a note that left the list

## What happens

Quando la nota esce dalla selezione corrente, per esempio dopo lo spostamento in un'altra cartella, l'editor continua a mostrare l'ultima versione ricevuta, con il lucchetto aggiornato. Il pulsante di protezione però decide cosa fare leggendo la nota com'era al momento dell'apertura. Se nel frattempo la nota è stata protetta, il pulsante la tratta come non protetta: con il PIN principale già impostato, **toglie il lucchetto senza chiedere il PIN**.

## What should happen

Il pulsante di protezione deve agire sulla stessa versione della nota che l'editor mostra. Togliere il lucchetto richiede sempre il PIN principale corretto, anche quando la nota è già sbloccata per la sessione, e spostare la nota non deve cambiare ciò che il pulsante fa.

## Fix options

### Agire sull'ultima versione mostrata

Il pulsante di protezione usa la stessa versione che l'editor mostra, come già fanno il menu e la condivisione. Togliere il lucchetto chiede il PIN e mettere il lucchetto funziona come adesso. Piccola modifica, coerente con il Model; nessun costo per l'utente.

### Leggere la nota dai dati locali

Il pulsante legge lo stato salvato della nota nel momento in cui viene premuto, quindi vede sempre la protezione reale anche se la nota è uscita dalla selezione. Corretto anche per note non più presenti nei dati, ma serve una lettura asincrona prima di chiedere il PIN e un caso in più da gestire.

### Nascondere il lucchetto fuori dalla selezione

Se la nota non è più nella lista, il pulsante di protezione non compare nell'editor e l'utente deve riaprirla dalla lista per cambiarla. Nessun rischio di togliere il lucchetto per errore, ma l'editor perde un comando che oggi funziona e il Model va aggiornato.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (_onLock: la nota di partenza è widget.note quando non è più nella lista, invece dell'ultima versione ricevuta)
