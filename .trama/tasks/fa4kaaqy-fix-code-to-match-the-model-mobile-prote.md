---
column: done
technical: false
refs:
  - note-editor/Protected
drift: qg0wycej
proposal: null
agent: false
created: 2026-10-13T14:07:59.001Z
finished: 2026-10-13T14:11:33.286Z
---
# Fix code to match the Model: Mobile protected note editor closes on trash or delete from its menu, the Model has no such exit

## What happens

Sul telefono, con una nota protetta aperta nell'editor, scegliere «Sposta nel cestino» o «Elimina definitivamente» dal menu chiude la schermata dell'editor, e il segnaposto «Questa nota è protetta» sparisce insieme alla schermata. Il Model descrive questa chiusura solo per lo stato Aperto della nota sbloccata. Nello stato Protetto c'è solo l'uscita con il pulsante indietro.

## What should happen

Il Model dice che una nota protetta resta nel segnaposto finché l'utente non la sblocca o non torna indietro. Per lo stato Protetto il Model non prevede che il cestino o l'eliminazione chiudano l'editor, quindi l'editor dovrebbe restare aperto sul segnaposto, come descrive il Model per lo stato Protetto.

## Chosen option

**Lasciare aperto il segnaposto dopo il cestino o l'eliminazione (recommended)**

Quando la nota protetta va nel cestino o viene eliminata dal menu, l'editor resta sul segnaposto, come dice il Model per lo stato Protetto, e l'utente torna all'elenco con il pulsante indietro. **Effetto:** nessun cambio al Model; il comportamento segue il Model. **Costo:** la schermata resta aperta su una nota che non è più nell'elenco, finché l'utente non torna indietro.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (_leave, chiamato da onRemoved del menu); lib/ui/notes_list/note_actions.dart (NoteMenuAction.trash e permanentlyDelete)
