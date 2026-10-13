---
status: resolved
resolution: proposal
refs:
  - mobile-navigation/Notes list/user.CREATE_NOTE
  - mobile-navigation/Folders/user.CREATE_NOTE
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ep2ayt04
created: 2026-10-12T08:23:53.030Z
---
# New note button hidden in trash on mobile

## What happens

Quando il cestino è la selezione corrente, la schermata con la lista delle note e quella delle Cartelle non mostrano il pulsante per creare una nota. Nel cestino non si può quindi creare una nota da mobile.

## What should happen

Il Model prevede la transizione di creazione della nota dalla lista note e dalle Cartelle senza eccezioni: crea una nota nella selezione corrente e apre subito il suo editor. Il Model non dice cosa succede quando la selezione è il cestino, perché una nota creata lì non sarebbe né eliminata né visibile nel cestino; la scelta va quindi presa esplicitamente.

## Fix options

### Keep the button hidden in trash

Il pulsante resta nascosto nel cestino, come ora. Il Model va precisato: la creazione vale per le altre selezioni. Nessun cambio di codice; nel cestino non si crea nulla, quindi non ci sono note nuove da ripristinare.

### Create the note in the Notes folder from trash

Il pulsante compare anche nel cestino e crea la nota nella cartella Note, aprendone subito l'editor. Il Model resta vero per la creazione. Costo: la nota compare fuori dalla vista in cui l'utente si trova, e il ritorno dall'editor non torna al cestino.

### Create the note directly in trash

Il pulsante compare nel cestino e la nota creata resta nel cestino, visibile nell'elenco. È la lettura letterale del Model. Costo: una nota nuova nel cestino contraddice la regola che il cestino contiene solo note eliminate; va chiarito come uscirne, cioè ripristino o eliminazione definitiva.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (barra in basso); lib/ui/mobile/mobile_folders_screen.dart (barra in basso); la creazione nel cestino è in lib/core/state/notes_provider.dart (createNote)
