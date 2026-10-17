---
status: resolved
resolution: proposal
refs:
  - mobile-navigation
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 7qmreh1i
created: 2026-10-17T08:02:40.813Z
---
# Model still says the mobile editor closes for a protected note after trash or delete

## What happens

Sul telefono, con una nota protetta aperta nell'editor, scegliere «Sposta nel cestino» o «Elimina definitivamente» dal menu lascia l'editor aperto sul segnaposto «Questa nota è protetta». Il Model di navigazione dice invece che l'editor si chiude sempre in questi due casi (Editing from list e Editing from folders). Il comportamento è quello deciso nel Drift qg0wycej.

## What should happen

Il Model di navigazione non distingue le note protette: per quelle la chiusura non c'è. Lo stato Protetto dell'editor prevede solo l'uscita con il pulsante indietro, e la decisione presa nel Drift qg0wycej è lasciare il segnaposto aperto. Il Model di navigazione non è stato aggiornato dopo quella decisione.

## Fix options

### Aggiornare il Model di navigazione

Le transizioni MOVE_NOTE_TO_TRASH e DELETE_NOTE_PERMANENTLY dell'editor aperto dalla lista e dalle Cartelle valgono per le note sbloccate; per una nota protetta l'editor resta sul segnaposto, come deciso nel Drift qg0wycej. Il codice non cambia.

### Chiudere l'editor anche per le note protette

Il codice torna a chiudere la schermata anche per le note protette, come dice oggi il Model di navigazione. La modifica annulla la decisione del Drift qg0wycej e lo stato Protetto dell'editor riceve la stessa uscita: va fatta con una Proposal separata.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: menu azioni dell'editor, onRemoved disattivato per le note protette; lib/ui/shell/adaptive_app_shell.dart: schermate Editing from list ed Editing from folders.
