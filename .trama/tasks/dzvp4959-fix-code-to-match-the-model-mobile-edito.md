---
column: done
technical: false
refs:
  - mobile-navigation/Editor from list
  - note-access/Unprotected
drift: l0o9ypcy
proposal: null
agent: false
created: 2026-10-17T18:07:16.470Z
finished: 2026-10-17T18:09:27.713Z
---
# Fix code to match the Model: Mobile editor keeps showing a note that another device protected after it left the list

## What happens

Sul telefono una nota aperta nell'editor esce dalla vista corrente, per esempio perché è stata spostata in un'altra cartella o ripristinata dal cestino. Poi un altro dispositivo la protegge con il lucchetto e la versione arriva qui. L'editor continua a mostrare il testo della nota come era prima: non compaiono né il segnaposto «Questa nota è protetta» né l'avviso, e il contenuto resta leggibile senza PIN.

## What should happen

Una nota protetta altrove si nasconde anche sul telefono, come ogni altra nota: l'editor mostra il segnaposto «Questa nota è protetta» con il pulsante «Visualizza nota», e il testo resta nascosto finché l'utente non inserisce il PIN. Resta invece vero che, quando la nota esce dalla lista, l'editor conserva l'ultima versione ricevuta.

## Chosen option

**Rileggere lo stato della nota a ogni cambiamento dei dati**

Mentre l'editor è aperto, a ogni cambiamento dei dati l'editor rilegge la nota salvata e ne aggiorna cartella, cestino, fissaggio e protezione, lasciando il testo com'è. Così il menu, la condivisione e il lucchetto seguono sempre lo stato salvato, come propone già la correzione del menu azioni. Costo: una lettura locale per ogni cambiamento dei dati mentre l'editor è aperto.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: currentNote parte da _lastKnownNote, che si aggiorna solo quando la nota è nella lista; lib/core/state/notes_provider.dart: _reloadLists, la lista non include più la nota uscita dalla vista; fetchNote non è usato dall'editor
