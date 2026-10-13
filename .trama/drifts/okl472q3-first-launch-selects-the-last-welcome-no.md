---
status: resolved
resolution: dismissed
refs:
  - note-selection/No note/note-browser.LIST_RELOADED
  - note-selection/No note/user.CREATE_NOTE
proposal: null
task: null
origin: null
critical: false
option: null
note: null
created: 2026-10-13T06:04:31.458Z
---
# First launch selects the last welcome note, not the first in the list

## What happens

Al primo avvio, le due note di benvenuto vengono create una dopo l'altra e ciascuna diventa la nota selezionata. Alla fine resta selezionata **«Pianificazione & Attività»**, la seconda creata. Il Model farebbe invece selezionare la prima nota dell'elenco, che è «Benvenuto in OpenNotes», fissata e quindi in cima.

## What should happen

Il Model dice che, senza nota selezionata, una ricarica dell'elenco seleziona la prima nota. La selezione cambia per una scelta dell'utente, per una nuova nota o una copia da lui create, oppure per la ricarica dell'elenco. Le note di benvenuto non sono create dall'utente: al primo avvio la selezione deve quindi andare alla prima nota dell'elenco, cioè alla nota fissata di benvenuto.

## Fix options

### Creare le note di benvenuto senza selezionarle

Le note di benvenuto vengono create senza cambiare la selezione. La ricarica dell'elenco che segue seleziona la prima nota, come previsto dal Model. La creazione fatta dall'utente continua a selezionare la nuova nota. Costo: serve un modo per creare una nota senza selezionarla, usato solo dal primo avvio.

### Selezionare esplicitamente la nota di benvenuto

Al termine della creazione delle note di benvenuto la nota «Benvenuto in OpenNotes» viene selezionata in modo esplicito. Il risultato è quello del Model, ma la regola sta nel codice di avvio invece che nell'elenco. Costo: una riga in più nell'avvio, da tenere allineata se cambiano l'ordine o il titolo delle note di benvenuto.

## Where in the code

lib/main.dart (_createWelcomeNotes); lib/core/state/notes_provider.dart (createNote, che seleziona sempre la nota creata)
