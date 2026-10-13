---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Notes list
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
proposal: null
task: 80yny053
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:46:44.152Z
---
# Long-press menu of the notes list trashes and deletes notes permanently

## What happens

Tenendo premuta una nota nella lista si apre il menu completo della nota. Oltre a duplicare, da lì si può spostare la nota nel cestino, e nel cestino anche eliminarla definitivamente, dopo conferma e PIN se protetta. La schermata non cambia: la nota sparisce dalla lista, senza passare dall'editor.

## What should happen

Il Modello dice che dalla lista si spostano note nel cestino solo con lo scorrimento, che l'eliminazione definitiva avviene solo dal menu azioni dell'editor nel cestino, e che la pressione prolungata serve a duplicare. Le altre azioni del menu della lista non sono descritte; quindi eliminare o cestinare dalla lista è un comportamento che il Modello non prevede.

## Fix options

### Togliere dal menu della lista le azioni di cestino ed eliminazione

Il menu della pressione prolungata resta con le azioni di organizzazione (fissa, protegge, duplica, sposta, condividi, esporta, ripristina), ma non sposta nel cestino e non elimina definitivamente. Restano lo scorrimento per il cestino e il menu dell'editor per l'eliminazione definitiva, come dice il Modello. Costo: chi vuole eliminare una nota dalla lista deve aprirla; il codice cambia e il Modello resta uguale.

### Descrivere nel Modello le azioni del menu della lista

Si aggiungono alla Machine delle note le transizioni di cestino ed eliminazione dal menu della pressione prolungata, con la stessa conferma e lo stesso PIN dell'editor e senza cambio di schermata. Costo: il Modello si allarga a tutte le azioni del menu, e ogni azione nuova dovrà essere decisa nel Modello; il codice resta uguale.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_showNoteContextMenu, pressione prolungata in _buildDismissibleNoteCard); lib/ui/notes_list/note_actions.dart (showMobile, handle); lib/ui/notes_list/note_action_menu.dart (actionsFor).
