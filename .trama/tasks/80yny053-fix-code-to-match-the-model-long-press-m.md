---
column: done
technical: false
refs:
  - mobile-navigation/Notes list
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
drift: amvt3yv7
proposal: null
agent: false
created: 2026-10-12T10:59:40.533Z
finished: 2026-10-12T11:04:00.183Z
---
# Fix code to match the Model: Long-press menu of the notes list trashes and deletes notes permanently

## What happens

Tenendo premuta una nota nella lista si apre il menu completo della nota. Oltre a duplicare, da lì si può spostare la nota nel cestino, e nel cestino anche eliminarla definitivamente, dopo conferma e PIN se protetta. La schermata non cambia: la nota sparisce dalla lista, senza passare dall'editor.

## What should happen

Il Modello dice che dalla lista si spostano note nel cestino solo con lo scorrimento, che l'eliminazione definitiva avviene solo dal menu azioni dell'editor nel cestino, e che la pressione prolungata serve a duplicare. Le altre azioni del menu della lista non sono descritte; quindi eliminare o cestinare dalla lista è un comportamento che il Modello non prevede.

## Chosen option

**Togliere dal menu della lista le azioni di cestino ed eliminazione**

Il menu della pressione prolungata resta con le azioni di organizzazione (fissa, protegge, duplica, sposta, condividi, esporta, ripristina), ma non sposta nel cestino e non elimina definitivamente. Restano lo scorrimento per il cestino e il menu dell'editor per l'eliminazione definitiva, come dice il Modello. Costo: chi vuole eliminare una nota dalla lista deve aprirla; il codice cambia e il Modello resta uguale.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_showNoteContextMenu, pressione prolungata in _buildDismissibleNoteCard); lib/ui/notes_list/note_actions.dart (showMobile, handle); lib/ui/notes_list/note_action_menu.dart (actionsFor).
